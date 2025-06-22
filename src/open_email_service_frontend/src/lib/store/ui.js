import { writable } from 'svelte/store';

export const showWriteMail = writable(false);
export const toggleWriteMail = () => showWriteMail.update(n => !n);
export const closeWriteMail = () => showWriteMail.set(false);