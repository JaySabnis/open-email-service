import { writable } from "svelte/store";
import { ProfileService } from "../services/profile.services";


function createProfilStore() {
  const { subscribe, set } = writable(undefined);

  async function createProfile(data) {
    return new ProfileService().createProfile(data);
  }

  async function getProfile() {
    return new ProfileService().getProfile();
  }

  async function updateProfile() {
    return new ProfileService().updateProfile();
  }
  return {
    createProfile,
    getProfile,
    updateProfile,
    subscribe,
  };
}

export const profileStore = createProfilStore();
