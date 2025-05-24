<script>
  import { onMount } from "svelte";
  import { signOut } from "$lib/services/auth.services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { profileStore } from "$lib/store/profile-store";
  import Loader from "$lib/components/loader.svelte";
  import { loadUserProfile } from "$lib/store/user";

  let name = '';
  let surname = '';
  let userAddress = '';
  let status = '';
  let description = '';
  let profile = null;
  let loading = true;
  let isEditMode = false;
  let addressValid = null; 
  let addressError = '';
  let addressTimer;
  let profileImageFile = null; 
  let profileImageBlob = null; 
  let profileImageUrl = '';

  if (!authSignedInStore) {
    signOut();
  }

 function opt(value) {
  if (value === undefined || value === null || value === '') {
    return [];  
  }
  return [value]; 
}


async function handleSubmit() {
  try {
    const newProfileImageArray = profileImageBlob
      ? await blobToUint8Array(profileImageBlob)
      : [];

    const optionalFields = {
      status: opt(status),
      description: opt(description),
      profileImage: newProfileImageArray.length ? opt(newProfileImageArray) : []
    };

    if (profile) {
      const updateData = {};

      updateData.name = opt(name);
      updateData.surname = opt(surname);
      updateData.userAddress = opt(userAddress);
      updateData.status = opt(status);
      updateData.description = opt(description);

      const currentImageArray = profile.data.profileImage || [];
      const imageChanged = (
        newProfileImageArray.length !== currentImageArray.length ||
        !newProfileImageArray.every((val, index) => val === currentImageArray[index])
      );

      if (imageChanged) updateData.profileImage = opt(newProfileImageArray);

      const hasChanged = Object.keys(updateData).length > 0;

      if (hasChanged) {
        console.log("Updating profile with:", updateData);
        await profileStore.updateProfile(updateData);
        const forceRefresh = true;
        await loadUserProfile(forceRefresh);
        window.dispatchEvent(new CustomEvent('profileUpdated'));
      } else {
        console.log("No changes detected");
      }

    } else {
      const createData = {
        name,
        surname,
        userAddress,
        ...optionalFields
      };

      console.log("Creating profile with:", createData);
      await profileStore.createProfile(createData);
    }

    await getUserProfile();
    isEditMode = false;
  } catch (error) {
    console.error("Error submitting profile:", error);
  }
}


function blobToUint8Array(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      resolve(new Uint8Array(reader.result));
    };
    reader.onerror = reject;
    reader.readAsArrayBuffer(blob);
  });
}



function handleImageUpload(event) {
  const file = event.target.files[0];
  if (file) {
    profileImageFile = file;
    const reader = new FileReader();
    reader.onloadend = () => {
      profileImageBlob = new Blob([reader.result], { type: file.type });
    };
    reader.readAsArrayBuffer(file);
  }
}


 function getUserProfile() {
    loading = true;
    profile = JSON.parse(localStorage.getItem('userProfileCache'))

    if (profile) {
      name = profile.data.name || '';
      surname = profile.data.surname || '';
      userAddress = profile.data.userAddress || '';
      status = profile.data.status || '';
      description = profile.data.description || '';
      profileImageUrl= profile.data.profileImage || ''
    }
    loading = false;
  }

  function onAddressInput(event) {
    userAddress = event.target.value;
    addressValid = null;
    addressError = '';
    clearTimeout(addressTimer);
    addressTimer = setTimeout(validateAddress, 500);
  }

  async function validateAddress() {
    if (!userAddress.trim()) return;
    try {
      const userAddressAvailable = await profileStore.isUserAddressAvailable(userAddress);
      addressValid = userAddressAvailable;
      addressError = userAddressAvailable ? '' : 'Address not available';
    } catch (err) {
      addressValid = false;
      addressError = 'Validation error';
      console.error(err);
    }
  }

  onMount(getUserProfile);
</script>


{#if loading}
  <Loader message="Fetching your profile.data..." />
{:else}
  {#if profile && !isEditMode}
<div class="relative max-w-3xl mx-auto bg-white shadow-md rounded-lg mt-10 p-6 flex flex-col sm:flex-row items-center sm:items-start space-y-6 sm:space-y-0 sm:space-x-8">
  <!-- Edit Button -->
  <button
    on:click={() => isEditMode = true}
    aria-label="Edit Profile"
    class="absolute top-4 right-4 text-gray-400 hover:text-blue-600 transition cursor-pointer"
    title="Edit Profile"
  >
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536M16.5 3.75a2.25 2.25 0 013.182 3.182L7.5 18.75H4.5v-3l12-12z" />
    </svg>
  </button>

  {#if profileImageUrl}
    <div class="flex-shrink-0">
      <img 
        src={profileImageUrl} 
        alt="Profile Image" 
        class="w-28 h-28 rounded-full object-cover border-4 border-blue-100 shadow-sm"
      />
    </div>
  {/if}

  <div class="flex-grow w-full grid grid-cols-1 sm:grid-cols-2 gap-y-3 gap-x-8 text-gray-700">
    <div>
      <p class="text-xs uppercase text-gray-400 font-semibold">First Name</p>
      <p class="text-lg font-semibold">{profile?.data?.name || '-'}</p>
    </div>

    <div>
      <p class="text-xs uppercase text-gray-400 font-semibold">Last Name</p>
      <p class="text-lg font-semibold">{profile?.data?.surname || '-'}</p>
    </div>

    <div>
      <p class="text-xs uppercase text-gray-400 font-semibold">Address</p>
      <p class="text-lg font-medium">{profile?.data?.userAddress || '-'}</p>
    </div>

    <div>
      <p class="text-xs uppercase text-gray-400 font-semibold">Status</p>
      <p class="text-lg font-medium">{profile?.data?.status || '-'}</p>
    </div>

    <div class="col-span-1 sm:col-span-2">
      <p class="text-xs uppercase text-gray-400 font-semibold">Description</p>
      <p class="text-md">{profile?.data?.description || '-'}</p>
    </div>
  </div>
</div>


  {:else}
<div class="max-w-3xl mx-auto p-6 bg-white shadow-lg rounded-lg mt-10">
  <h1 class="text-2xl font-semibold mb-6 text-center">{profile ? 'Update Profile' : 'Create Profile'}</h1>

  <form on:submit|preventDefault={handleSubmit} class="space-y-6">

    {#if profileImageUrl || profileImageBlob}
      <div class="flex justify-center">
        <img 
          src={profileImageBlob ? URL.createObjectURL(profileImageBlob) : profileImageUrl} 
          alt="Profile Preview" 
          class="w-32 h-32 rounded-full object-cover border-2 border-gray-200"
        />
      </div>
    {/if}

    <div class="relative">
      <input
        id="name"
        type="text"
        bind:value={name}
        placeholder=" "
        required
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition"
      />
      <label
        for="name"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        First Name
      </label>
    </div>

    <div class="relative">
      <input
        id="surname"
        type="text"
        bind:value={surname}
        placeholder=" "
        required
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition"
      />
      <label
        for="surname"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        Last Name
      </label>
    </div>

    <div class="relative">
      <input
        id="address"
        type="text"
        bind:value={userAddress}
        placeholder=" "
        disabled={profile}
        on:input={onAddressInput}
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent
               focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white pr-10 disabled:bg-gray-200 disabled:cursor-not-allowed transition"
      />
      <label
        for="address"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        Address
      </label>
      <div class="absolute inset-y-0 right-3 flex items-center pointer-events-none">
        {#if addressValid === true}
          <span class="text-green-500">✓</span>
        {:else if addressValid === false}
          <span class="text-red-500">✕</span>
        {/if}
      </div>
      {#if addressError}
        <p class="text-red-600 text-sm mt-1">{addressError}</p>
      {/if}
    </div>

    <div class="relative">
      <input
        id="profileImage"
        type="file"
        accept="image/*"
        on:change={handleImageUpload}
        placeholder=" "
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition"
      />
      <label
        for="profileImage"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        Profile Image
      </label>
    </div>

    <div class="relative">
      <input
        id="status"
        type="text"
        bind:value={status}
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition"
        placeholder="Enter your status"
      />
      <label
        for="status"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        Status
      </label>
    </div>

    <div class="relative">
      <textarea
        id="description"
        rows="3"
        bind:value={description}
        class="peer w-full rounded-md bg-gray-100 px-4 pt-5 pb-2 text-lg font-medium text-gray-900 placeholder-transparent resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition"
        placeholder="Enter a brief description"
      ></textarea>
      <label
        for="description"
        class="absolute left-4 top-2 text-gray-500 text-sm pointer-events-none transition-all duration-200 origin-left
               peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-placeholder-shown:font-normal
               peer-focus:top-2 peer-focus:text-sm peer-focus:text-blue-600 peer-focus:font-medium"
      >
        Description
      </label>
    </div>

    <div class="text-center space-x-4">
      <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition">
        {profile ? 'Update' : 'Save'} Profile
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
