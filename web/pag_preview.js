/**
 * Thin bridge: Flutter hosts an iframe pointing at pag_player.html.
 * Actual libpag work happens only inside that page (avoids CanvasKit clashes).
 *
 * A brand-new iframe (fresh window/WASM heap) is created for EVERY play call
 * and torn down afterwards. Reusing one iframe/document across multiple plays
 * left a window for a previous PAGView's render loop callback to fire after
 * destroy(), touching a freed WASM handle — that is what caused
 * "BindingError: Cannot use deleted val. handle = 0". A fresh document per
 * play makes that impossible: there is nothing left alive to touch.
 */
(function () {
  'use strict';

  var PLAYER_SRC = 'pag_player.html?v=5';
  var hosts = Object.create(null);
  var playGens = Object.create(null);
  var chain = Promise.resolve();

  function enqueue(task) {
    chain = chain.then(task, task);
    return chain;
  }

  function bumpGen(id) {
    var next = (playGens[id] || 0) + 1;
    playGens[id] = next;
    return next;
  }

  function isCurrent(id, gen) {
    return playGens[id] === gen;
  }

  function waitForElement(id, timeoutMs) {
    return new Promise(function (resolve, reject) {
      var started = Date.now();
      function tick() {
        var el = document.getElementById(id);
        if (el) {
          resolve(el);
          return;
        }
        if (Date.now() - started > timeoutMs) {
          reject(new Error('PAG container not found: ' + id));
          return;
        }
        requestAnimationFrame(tick);
      }
      tick();
    });
  }

  function waitForBoot(iframe, timeoutMs) {
    return new Promise(function (resolve, reject) {
      var done = false;
      var timer = setTimeout(function () {
        if (done) return;
        done = true;
        window.removeEventListener('message', onMessage);
        reject(new Error('PAG player iframe boot timeout — hard refresh the page'));
      }, timeoutMs);

      function onMessage(event) {
        var data = event.data;
        if (!data || data.source !== 'gift-pag-player') return;
        if (event.source !== iframe.contentWindow) return;
        if (data.type !== 'boot') return;
        if (done) return;
        done = true;
        clearTimeout(timer);
        window.removeEventListener('message', onMessage);
        resolve();
      }

      window.addEventListener('message', onMessage);
    });
  }

  function waitForPlayResult(iframe, gen, containerId, timeoutMs) {
    return new Promise(function (resolve, reject) {
      var done = false;
      var timer = setTimeout(function () {
        if (done) return;
        done = true;
        window.removeEventListener('message', onMessage);
        reject(new Error('PAG play timeout'));
      }, timeoutMs);

      function finish(fn) {
        if (done) return;
        done = true;
        clearTimeout(timer);
        window.removeEventListener('message', onMessage);
        fn();
      }

      function onMessage(event) {
        var data = event.data;
        if (!data || data.source !== 'gift-pag-player') return;
        if (event.source !== iframe.contentWindow) return;
        if (!isCurrent(containerId, gen)) {
          finish(function () {
            resolve(false);
          });
          return;
        }
        if (data.type === 'ready') {
          finish(function () {
            resolve(true);
          });
          return;
        }
        if (data.type === 'error') {
          finish(function () {
            reject(new Error(data.message || 'PAG play failed'));
          });
        }
      }

      window.addEventListener('message', onMessage);
    });
  }

  function createHost(containerId) {
    return waitForElement(containerId, 8000).then(function (container) {
      while (container.firstChild) {
        container.removeChild(container.firstChild);
      }

      var iframe = document.createElement('iframe');
      iframe.setAttribute('title', 'PAG preview');
      iframe.setAttribute('allow', 'autoplay');
      iframe.style.cssText =
        'border:0;width:100%;height:100%;display:block;background:#111318;';

      // Listen before attaching so we never miss the boot message.
      var bootPromise = waitForBoot(iframe, 20000);
      iframe.src = PLAYER_SRC;
      container.appendChild(iframe);

      return bootPromise.then(function () {
        var host = { iframe: iframe };
        hosts[containerId] = host;
        return host;
      });
    });
  }

  function destroyHost(containerId) {
    var host = hosts[containerId];
    if (!host) return;
    delete hosts[containerId];
    try {
      if (host.iframe && host.iframe.parentNode) {
        host.iframe.parentNode.removeChild(host.iframe);
      }
    } catch (_) {}
  }

  function playOnContainer(containerId, payload) {
    var gen = bumpGen(containerId);

    // Always tear down and recreate: a brand-new iframe means a brand-new
    // JS realm + WASM heap, so nothing from a previous play can ever be
    // touched again.
    destroyHost(containerId);

    return createHost(containerId).then(function (host) {
      if (!isCurrent(containerId, gen)) {
        destroyHost(containerId);
        return false;
      }

      var resultPromise = waitForPlayResult(
        host.iframe,
        gen,
        containerId,
        60000,
      );

      host.iframe.contentWindow.postMessage(
        Object.assign(
          { target: 'gift-pag-player', type: 'play' },
          payload,
        ),
        '*',
        payload.buffer ? [payload.buffer] : undefined,
      );

      return resultPromise;
    });
  }

  window.GiftPagPreview = {
    playFromUrl: function (containerId, url) {
      return enqueue(function () {
        return playOnContainer(containerId, { url: url });
      });
    },

    playFromBytes: function (containerId, bytes) {
      return enqueue(function () {
        var buffer = null;
        if (bytes instanceof ArrayBuffer) {
          buffer = bytes.slice(0);
        } else if (ArrayBuffer.isView(bytes)) {
          buffer = bytes.buffer.slice(
            bytes.byteOffset,
            bytes.byteOffset + bytes.byteLength,
          );
        }
        if (!buffer) {
          return Promise.reject(new Error('Invalid PAG bytes'));
        }
        return playOnContainer(containerId, { buffer: buffer });
      });
    },

    destroy: function (containerId) {
      bumpGen(containerId);
      return enqueue(function () {
        destroyHost(containerId);
        return true;
      });
    },

    isReady: function () {
      return true;
    },
  };
})();
