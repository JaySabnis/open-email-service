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

  async function updateProfile(data) {
    return new ProfileService().updateProfile(data);
  }

  async function isUserAddressAvailable(userAddress){
    return new ProfileService().isUserAddressAvailable(userAddress);
  }

  return {
    createProfile,
    getProfile,
    updateProfile,
    subscribe,
    isUserAddressAvailable
  };
}

export const profileStore = createProfilStore();
