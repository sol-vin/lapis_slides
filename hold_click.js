window.SOLVIN_PALETTE_ICONS = Object.assign(window.SOLVIN_PALETTE_ICONS || {}, {"palette":"<svg class=\"project-icon-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\"><!--! Font Awesome Pro 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2025 Fonticons, Inc. --><path fill=\"currentColor\" d=\"M512 256c0 .9 0 1.8 0 2.7-.4 36.5-33.6 61.3-70.1 61.3L344 320c-26.5 0-48 21.5-48 48 0 3.4 .4 6.7 1 9.9 2.1 10.2 6.5 20 10.8 29.9 6.1 13.8 12.1 27.5 12.1 42 0 31.8-21.6 60.7-53.4 62-3.5 .1-7 .2-10.6 .2-141.4 0-256-114.6-256-256S114.6 0 256 0 512 114.6 512 256zM128 288a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm0-96a32 32 0 1 0 0-64 32 32 0 1 0 0 64zM288 96a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm96 96a32 32 0 1 0 0-64 32 32 0 1 0 0 64z\"/></svg>","dice":"<svg class=\"project-icon-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\"><!--! Font Awesome Pro 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2025 Fonticons, Inc. --><path fill=\"currentColor\" d=\"M141.4 2.3C103-8 63.5 14.8 53.3 53.2L2.5 242.7C-7.8 281.1 15 320.6 53.4 330.9l189.5 50.8c38.4 10.3 77.9-12.5 88.2-50.9l50.8-189.5c10.3-38.4-12.5-77.9-50.9-88.2L141.4 2.3zm23 205.7a32 32 0 1 1 55.4-32 32 32 0 1 1 -55.4 32zM79.2 220.3a32 32 0 1 1 32 55.4 32 32 0 1 1 -32-55.4zm185 96.4a32 32 0 1 1 -32-55.4 32 32 0 1 1 32 55.4zm9-208.4a32 32 0 1 1 32 55.4 32 32 0 1 1 -32-55.4zm-121 14.4a32 32 0 1 1 -32-55.4 32 32 0 1 1 32 55.4zM418 192L377.4 343.2c-17.2 64-83 102-147 84.9l-38.3-10.3 0 30.2c0 35.3 28.7 64 64 64l192 0c35.3 0 64-28.7 64-64l0-192c0-35.3-28.7-64-64-64L418 192z\"/></svg>","xmark":"<svg class=\"project-icon-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 384 512\"><!--! Font Awesome Pro 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2025 Fonticons, Inc. --><path fill=\"currentColor\" d=\"M55.1 73.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L147.2 256 9.9 393.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L192.5 301.3 329.9 438.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L237.8 256 375.1 118.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L192.5 210.7 55.1 73.4z\"/></svg>","bracketLeft":"<svg class=\"project-icon-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 192 512\"><!--! Font Awesome Pro 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2025 Fonticons, Inc. --><path fill=\"currentColor\" d=\"M0 96C0 60.7 28.7 32 64 32l64 0c17.7 0 32 14.3 32 32s-14.3 32-32 32l-64 0 0 320 64 0c17.7 0 32 14.3 32 32s-14.3 32-32 32l-64 0c-35.3 0-64-28.7-64-64L0 96z\"/></svg>","bracketRight":"<svg class=\"project-icon-svg\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 192 512\"><!--! Font Awesome Pro 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2025 Fonticons, Inc. --><path fill=\"currentColor\" d=\"M192 96c0-35.3-28.7-64-64-64L64 32C46.3 32 32 46.3 32 64S46.3 96 64 96l64 0 0 320-64 0c-17.7 0-32 14.3-32 32s14.3 32 32 32l64 0c35.3 0 64-28.7 64-64l0-320z\"/></svg>","holdSpinner":"<svg width=\"32\" height=\"32\" viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"16\" cy=\"16\" r=\"14\" class=\"spinner-base\" /><circle cx=\"16\" cy=\"16\" r=\"11.0\" class=\"spinner-track\" /><circle cx=\"16\" cy=\"16\" r=\"11.0\" class=\"spinner-progress\" /><circle cx=\"16\" cy=\"16\" r=\"3.5\" class=\"spinner-dot\" /></svg>"});
/**
 * HoldClick - Reusable Left/Right Click & Hold Handler with Progress Spinner
 * Zero-dependency UMD/Browser module exported from sol-vin/sol.vin for Sunstone.
 */
(function(root) {
  'use strict';

  function getSpinnerMarkup() {
    var injected = (root && root.SOLVIN_PALETTE_ICONS) || (typeof window !== 'undefined' && window.SOLVIN_PALETTE_ICONS);
    if (injected && injected.holdSpinner) {
      return injected.holdSpinner;
    }
    return '<img src="/icons/hold-spinner.svg" data-svg-src="src/web/svgs/hold-spinner.svg" width="32" height="32" alt="" />';
  }

  var SPINNER_SVG = getSpinnerMarkup();

  function HoldClick(target, options) {
    if (!(this instanceof HoldClick)) {
      return new HoldClick(target, options);
    }

    this.options = Object.assign({
      holdDuration: 2000,                  // Total hold time (ms) = 500ms delay + 1500ms charge up
      spinnerDelay: 500,                   // Delay before showing spinner (ms)
      spinnerId: 'palette-hold-spinner',   // DOM ID for floating progress ring
      delegateSelector: null,              // Optional selector for event delegation
      onLeftClick: null,                   // Callback(e, targetEl)
      onRightClick: null,                  // Callback(e, targetEl)
      onLeftHold: null,                    // Callback(e, targetEl)
      onRightHold: null                    // Callback(e, targetEl)
    }, options || {});

    this.container = (typeof target === 'string' && typeof document !== 'undefined')
      ? document.querySelector(target)
      : target;
    if (!this.container) return;

    this.animFrameId = null;
    this.heldLong = false;
    this.mouseX = 0;
    this.mouseY = 0;
    this.spinnerEl = null;
    this.progressCircle = null;
    this.circumference = 2 * Math.PI * 11; // ~69.115

    this._onMouseMove = this._onMouseMove.bind(this);
    this._onMouseDown = this._onMouseDown.bind(this);
    this._onMouseUp = this._onMouseUp.bind(this);
    this._onMouseLeave = this._onMouseLeave.bind(this);
    this._onClick = this._onClick.bind(this);
    this._onContextMenu = this._onContextMenu.bind(this);

    this.init();
  }

  HoldClick.SPINNER_SVG = SPINNER_SVG;

  HoldClick.prototype.ensureSpinner = function() {
    if (this.spinnerEl || typeof document === 'undefined') return;
    var spinnerId = this.options.spinnerId || 'palette-hold-spinner';
    var existing = document.getElementById(spinnerId);
    if (existing) {
      this.spinnerEl = existing;
    } else {
      this.spinnerEl = document.createElement('div');
      this.spinnerEl.id = spinnerId;
      this.spinnerEl.className = 'palette-hold-spinner hold-click-spinner';
      this.spinnerEl.innerHTML = getSpinnerMarkup();
      document.body.appendChild(this.spinnerEl);
    }
    this.progressCircle = this.spinnerEl.querySelector('.spinner-progress');
  };

  HoldClick.prototype._updateSpinnerPos = function(e) {
    if (e) {
      this.mouseX = e.clientX;
      this.mouseY = e.clientY;
    }
    if (this.spinnerEl) {
      this.spinnerEl.style.left = (this.mouseX + 14) + 'px';
      this.spinnerEl.style.top = (this.mouseY + 14) + 'px';
    }
  };

  HoldClick.prototype._onMouseMove = function(e) {
    this._updateSpinnerPos(e);
  };

  HoldClick.prototype.stopHoldAnimation = function() {
    if (this.animFrameId && typeof cancelAnimationFrame === 'function') {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
    if (this.spinnerEl) {
      this.spinnerEl.classList.remove('is-visible');
    }
    if (typeof window !== 'undefined') {
      window.removeEventListener('mousemove', this._onMouseMove);
    }
  };

  HoldClick.prototype.getTargetElement = function(e) {
    if (!e || !e.target) return null;
    if (this.options.delegateSelector && typeof e.target.closest === 'function') {
      return e.target.closest(this.options.delegateSelector);
    }
    return (this.container && typeof this.container.contains === 'function' && this.container.contains(e.target))
      ? this.container
      : null;
  };

  HoldClick.prototype._onMouseDown = function(e) {
    var targetEl = this.getTargetElement(e);
    if (!targetEl) return;

    if (e.button !== 0 && e.button !== 2) return;

    this.stopHoldAnimation();
    this.ensureSpinner();
    this.heldLong = false;

    this._updateSpinnerPos(e);
    if (typeof window !== 'undefined') {
      window.addEventListener('mousemove', this._onMouseMove);
    }

    var self = this;
    var startTime = Date.now();
    var isLeftClick = (e.button === 0);
    var holdDuration = this.options.holdDuration;
    var spinnerDelay = this.options.spinnerDelay;

    function step() {
      var elapsed = Date.now() - startTime;
      if (elapsed >= spinnerDelay) {
        if (self.spinnerEl) {
          self.spinnerEl.classList.add('is-visible');
        }
        var progress = Math.min(1, Math.max(0, (elapsed - spinnerDelay) / (holdDuration - spinnerDelay)));
        if (self.progressCircle) {
          var offset = self.circumference * (1 - progress);
          self.progressCircle.style.strokeDashoffset = offset + 'px';
          self.progressCircle.setAttribute('stroke-dashoffset', offset);
        }
      } else {
        if (self.spinnerEl) {
          self.spinnerEl.classList.remove('is-visible');
        }
      }

      if (elapsed >= holdDuration) {
        self.heldLong = true;
        self.stopHoldAnimation();

        if (isLeftClick) {
          if (typeof self.options.onLeftHold === 'function') {
            self.options.onLeftHold(e, targetEl);
          }
        } else {
          if (typeof self.options.onRightHold === 'function') {
            self.options.onRightHold(e, targetEl);
          }
        }
      } else if (typeof requestAnimationFrame === 'function') {
        self.animFrameId = requestAnimationFrame(step);
      }
    }

    if (typeof requestAnimationFrame === 'function') {
      this.animFrameId = requestAnimationFrame(step);
    }
  };

  HoldClick.prototype._onMouseUp = function() {
    this.stopHoldAnimation();
  };

  HoldClick.prototype._onMouseLeave = function() {
    this.stopHoldAnimation();
  };

  HoldClick.prototype._onClick = function(e) {
    var targetEl = this.getTargetElement(e);
    if (!targetEl) return;

    e.preventDefault();
    this.stopHoldAnimation();

    if (this.heldLong) {
      this.heldLong = false;
      return;
    }

    if (typeof this.options.onLeftClick === 'function') {
      this.options.onLeftClick(e, targetEl);
    }
  };

  HoldClick.prototype._onContextMenu = function(e) {
    var targetEl = this.getTargetElement(e);
    if (!targetEl) return;

    e.preventDefault();
    this.stopHoldAnimation();

    if (this.heldLong) {
      this.heldLong = false;
      return;
    }

    if (typeof this.options.onRightClick === 'function') {
      this.options.onRightClick(e, targetEl);
    }
  };

  HoldClick.prototype.init = function() {
    if (!this.container || typeof this.container.addEventListener !== 'function') return;
    this.container.addEventListener('mousedown', this._onMouseDown);
    this.container.addEventListener('mouseup', this._onMouseUp);
    this.container.addEventListener('mouseleave', this._onMouseLeave);
    this.container.addEventListener('click', this._onClick);
    this.container.addEventListener('contextmenu', this._onContextMenu);
  };

  HoldClick.prototype.destroy = function() {
    this.stopHoldAnimation();
    if (!this.container || typeof this.container.removeEventListener !== 'function') return;
    this.container.removeEventListener('mousedown', this._onMouseDown);
    this.container.removeEventListener('mouseup', this._onMouseUp);
    this.container.removeEventListener('mouseleave', this._onMouseLeave);
    this.container.removeEventListener('click', this._onClick);
    this.container.removeEventListener('contextmenu', this._onContextMenu);
  };

  HoldClick.attach = function(target, options) {
    return new HoldClick(target, options);
  };

  if (root) {
    root.HoldClick = HoldClick;
  }
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = HoldClick;
  }
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : this));
