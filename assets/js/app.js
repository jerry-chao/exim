// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
// import "./user_socket"

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
// Hook for auto-dismissing flash messages
let Hooks = {};
Hooks.AutoDismissFlash = {
  mounted() {
    // Auto-dismiss after 1 second
    setTimeout(() => {
      if (this.el) {
        this.el.style.transition = 'opacity 0.3s ease-out';
        this.el.style.opacity = '0';
        
        // Remove from DOM after fade out
        setTimeout(() => {
          if (this.el && this.el.parentNode) {
            // Trigger the Phoenix LiveView clear flash event
            if (this.el.hasAttribute('phx-click')) {
              this.el.click();
            } else {
              this.el.remove();
            }
          }
        }, 300);
      }
    }, 1000);
  }
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// Flash message auto-dismiss functionality
function autoDismissFlashMessages() {
  const flashMessages = document.querySelectorAll('[phx-click="lv:clear-flash"]');
  
  flashMessages.forEach((flash) => {
    // Skip if already processed
    if (flash.dataset.processed === 'true') return;
    flash.dataset.processed = 'true';
    
    // Auto-dismiss after 1 second (1000ms)
    setTimeout(() => {
      if (flash && flash.parentNode) {
        flash.style.transition = 'opacity 0.3s ease-out';
        flash.style.opacity = '0';
        
        // Remove from DOM after fade out
        setTimeout(() => {
          if (flash && flash.parentNode) {
            // Try to trigger the Phoenix LiveView clear flash event
            if (flash.getAttribute('phx-click')) {
              flash.click();
            } else {
              flash.remove();
            }
          }
        }, 300);
      }
    }, 1000);
  });
}

// Also handle flash messages with different selectors
function autoDismissAllFlashMessages() {
  // Handle Phoenix LiveView flash messages
  autoDismissFlashMessages();
  
  // Handle other flash message formats
  const otherFlashMessages = document.querySelectorAll('[data-flash], .flash, .alert');
  
  otherFlashMessages.forEach((flash) => {
    if (flash.dataset.processed === 'true') return;
    flash.dataset.processed = 'true';
    
    setTimeout(() => {
      if (flash && flash.parentNode) {
        flash.style.transition = 'opacity 0.3s ease-out';
        flash.style.opacity = '0';
        
        setTimeout(() => {
          if (flash && flash.parentNode) {
            flash.remove();
          }
        }, 300);
      }
    }, 1000);
  });
}

// Run auto-dismiss on page load
document.addEventListener('DOMContentLoaded', autoDismissAllFlashMessages);

// Run auto-dismiss when LiveView updates the page
window.addEventListener('phx:page-loading-stop', autoDismissAllFlashMessages);

// Listen for LiveView flash events
window.addEventListener('phx:flash-added', autoDismissAllFlashMessages);

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
