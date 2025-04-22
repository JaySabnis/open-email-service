<script>
  import { onMount } from "svelte";
  import { signOut } from "$lib/services/auth.service";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { profileStore } from "$lib/store/profile-store";
  import Loader from "$lib/components/loader.svelte";

  let name = '';
  let surname = '';
  let userAddress = '';
  let status = '';
  let description = '';
  let profile = null;
  let loading = true;
  let isEditMode = false;

  if (!authSignedInStore) {
    signOut();
  }

  async function handleSubmit() {
  const profileData = {
    name,
    surname,
    status,
    description
  };

  if (profile.ok) {
    const hasChanged =
      name !== profile.ok.name ||
      surname !== profile.ok.surname ||
      status !== profile.ok.status ||
      description !== profile.ok.description;

    if (hasChanged) {
      await profileStore.updateProfile(profileData);
      // console.log(profileData, "Updated ProfileData");
    } else {
      console.log("No changes detected. Skipping update.");
    }
  } else {
    await profileStore.createProfile({ ...profileData, userAddress });
    // console.log(profileData, "Created ProfileData");
  }

  await getUserProfile();
  isEditMode = false;
}


  async function getUserProfile() {
    loading = true;
    profile = await profileStore.getProfile();
    // console.log(profile,"profile")

    if (profile.ok) {
      name = profile?.ok?.name || '';
      surname = profile?.ok?.surname || '';
      userAddress = profile?.ok?.userAddress || '';
      status = profile?.ok?.status || '';
      description = profile?.ok?.description || '';
    }

    loading = false;
  }

  onMount(async () => {
    await getUserProfile();
  });
</script>

{#if loading}
  <Loader message="Fetching your profile..." />
{:else}
  {#if profile.ok && !isEditMode}
    <div class="max-w-3xl mx-auto p-6 bg-white shadow-lg rounded-lg mt-10 space-y-4">
      <h1 class="text-2xl font-semibold text-center">Profile Details</h1>
      <p><strong>First Name:</strong> {profile?.ok?.name}</p>
      <p><strong>Last Name:</strong> {profile?.ok?.surname}</p>
      <p><strong>Address:</strong> {profile?.ok?.userAddress}</p>
      <p><strong>Status:</strong> {profile?.ok?.status}</p>
      <p><strong>Description:</strong> {profile?.ok?.description}</p>
      <div class="text-center mt-6">
        <button on:click={() => isEditMode = true} class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition">
          Edit Profile
        </button>
      </div>
    </div>
  {:else}
    <div class="max-w-3xl mx-auto p-6 bg-white shadow-lg rounded-lg mt-10">
      <h1 class="text-2xl font-semibold mb-6 text-center">{profile.ok ? 'Update Profile' : 'Create Profile'}</h1>

      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        <div>
          <label for="name" class="block text-sm font-medium mb-1">First Name</label>
          <input
            id="name"
            type="text"
            bind:value={name}
            class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
          />
        </div>

        <div>
          <label for="surname" class="block text-sm font-medium mb-1">Last Name</label>
          <input
            id="surname"
            type="text"
            bind:value={surname}
            class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
          />
        </div>

        <div class="relative">
          <label for="address" class="block text-sm font-medium mb-1">Address</label>
          <input
            id="address"
            type="text"
            bind:value={userAddress}
            class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300 pr-10"
            readonly={profile.ok && isEditMode}
          />
        
          <div class="absolute top-9 right-3 group cursor-pointer">
            <div class="w-5 h-5 flex items-center justify-center text-xs font-bold bg-blue-500 text-white rounded-full">
              i
            </div>
            
            <div class="absolute -top-10 right-0 bg-gray-700 text-white text-xs rounded py-1 px-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-10 whitespace-nowrap">
              Address cannot be updated
            </div>
          </div>
        </div>        

        <div>
          <label for="status" class="block text-sm font-medium mb-1">Status</label>
          <input
            id="status"
            type="text"
            bind:value={status}
            class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
            placeholder="Enter your status"
          />
        </div>

        <div>
          <label for="description" class="block text-sm font-medium mb-1">Description</label>
          <textarea
            id="description"
            rows="3"
            bind:value={description}
            class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
            placeholder="Enter a brief description"
          ></textarea>
        </div>

        <div class="text-center space-x-4">
          <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition">
            {profile.ok ? 'Update' : 'Save'} Profile
          </button>
          {#if profile}
            <button type="button" on:click={() => isEditMode = false} class="border border-gray-400 px-4 py-2 rounded-md hover:bg-gray-100 transition">
              Cancel
            </button>
          {/if}
        </div>
      </form>
    </div>
  {/if}
{/if}
