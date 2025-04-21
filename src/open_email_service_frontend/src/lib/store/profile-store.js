import { writable } from "svelte/store";
import { ProfileService } from "../services/profile.services";


function createProfilStore() {
  const { subscribe, set } = writable(undefined);

  async function createProfile(data) {
    return new ProfileService().createProfile(data);
  }
  return {
    createProfile,
    subscribe,
  };
}

export const profileStore = createProfilStore();
