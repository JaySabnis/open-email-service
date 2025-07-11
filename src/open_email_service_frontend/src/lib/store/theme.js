import { writable } from 'svelte/store';

export const theme = writable('light');

if (typeof window !== 'undefined') {
  const saved = localStorage.getItem('theme');
  if (saved) theme.set(saved);

  theme.subscribe((value) => {
    localStorage.setItem('theme', value);
    document.documentElement.classList.toggle('dark', value === 'dark');
  });
}
