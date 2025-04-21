import { writable } from "svelte/store";

function createToastsStore() {
  const { subscribe, update } = writable([]);
  let idCounter = 0;

  function addToast(toast) {
    update((toasts) => [...toasts, { ...toast, id: ++idCounter }]);
  }

  function removeToast(id) {
    update((toasts) => toasts.filter((toast) => toast.id !== id));
  }

  return {
    subscribe,
    addToast,
    removeToast,
  };
}

export const toasts = createToastsStore();
export const { addToast } = toasts;
