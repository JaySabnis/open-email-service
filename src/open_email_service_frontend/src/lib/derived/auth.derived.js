import { authStore } from '../store/auth-store'
import { derived } from "svelte/store";
export const authSignedInStore= derived(
  authStore,
  ({ identity }) => identity !== null && identity !== undefined,
);
