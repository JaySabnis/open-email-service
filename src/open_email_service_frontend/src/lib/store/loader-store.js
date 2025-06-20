import { writable } from 'svelte/store';

export const loaderStore = writable({
  isLoading: false,
  message: 'Loading...'
});

export function showLoader(message = 'Loading...') {
  loaderStore.set({ isLoading: true, message });
}

export function hideLoader() {
  loaderStore.set({ isLoading: false, message: '' });
}