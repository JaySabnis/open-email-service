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

  async function getProfileByUserAddress(userAddress){
    return new ProfileService().getProfileByUserAddress(userAddress);
  }

  async function deleteProfile() {
    return new ProfileService().deleteProfile();
  }

  return {
    createProfile,
    getProfile,
    updateProfile,
    subscribe,
    isUserAddressAvailable,
    getProfileByUserAddress,
    deleteProfile
  };
}

export const profileStore = createProfilStore();
