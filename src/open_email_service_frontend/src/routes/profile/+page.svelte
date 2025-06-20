<script>
  import { onMount, onDestroy } from "svelte";
  import { signOut } from "$lib/services/auth.services";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { profileStore } from "$lib/store/profile-store";
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from 'svelte/store';
  import { goto } from "$app/navigation"; 
    
  let name = '';
  let surname = '';
  let userAddress = '';
  let status = '';
  let description = '';
  let profile = null;
  let isEditMode = false;
  let addressValid = null; 
  let addressError = '';
  let addressTimer;
  let profileImageFile = null; 
  let profileImageBlob = null; 
  let profileImageUrl = '';
  let currentTheme;
  let currentColors;
  let showSuccess = false;
  let submitting = false;

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
    if (typeof window !== "undefined") {
      if (value === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  });

  function opt(value) {
    if (value === undefined || value === null || value === '') {
      return [];  // represents absence of value
    }
    return [value];  // not wrapped in array
  }

  async function handleSubmit() {
    try {
      submitting = true;
      showLoader(profile ? "Updating profile..." : "Creating profile...");
      
      const newProfileImageArray = profileImageBlob
        ? await blobToUint8Array(profileImageBlob)
        : profileImageUrl;

      if (profile) {
        const updateData = {
          name: (name !== profile.name ? opt(name) : opt(profile.name)),
          surname: (surname !== profile.surname ? opt(surname) : opt(profile.surname)),
          userAddress: (userAddress !== profile.userAddress ? opt(userAddress) : profile.userAddress),
          status: (status !== profile.status ? opt(status) : profile.status),
          description: (description !== profile.description ? opt(description) : profile.description)
        };

        const currentImageArray = profile.profileImage || [];
        const imageChanged = (
          newProfileImageArray.length !== currentImageArray.length ||
          !newProfileImageArray.every((val, index) => val === currentImageArray[index])
        );

        updateData.profileImage = imageChanged 
          ? opt(newProfileImageArray) 
          : (currentImageArray);

        await profileStore.updateProfile(updateData);
        await getUserProfile();
      } else {
        const createData = {
          name: name,
          surname: surname,
          userAddress: userAddress,
          status: opt(status),
          description: opt(description),
          profileImage: newProfileImageArray.length ? opt(newProfileImageArray) : []
        };

        await profileStore.createProfile(createData);
        await goto('/home');
      }
      
      showSuccess = true;
      window.dispatchEvent(new CustomEvent('profileUpdated'));
      await new Promise(resolve => setTimeout(resolve, 1500));
      showSuccess = false;
      isEditMode = false;
    } catch (error) {
      console.error("Error submitting profile:", error);
    } finally {
      submitting = false;
      hideLoader();
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

  async function getUserProfile() {
    try {
      showLoader('Loading profile...');
      const res = await profileStore.getProfile();
      profile = res?.ok || null;
      if (profile) {
        name = profile.name || '';
        surname = profile.surname || '';
        userAddress = profile.userAddress || '';
        status = profile.status || '';
        description = profile.description || '';
        profileImageUrl = profile.profileImage || '';
      }
    } catch (err) {
      console.error("Profile fetch failed:", err);
    } finally {
      hideLoader();
    }
  }

  onMount(() => {
    (async () => {
      if (!authSignedInStore) {
        console.warn("User is not signed in, redirecting to login page");
        signOut();
      }
      
      await getUserProfile();  
    })();
  });

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

  onDestroy(() => {
    unsubscribeTheme();
  });
</script>



<svelte:head>
  <title>Profile</title>
</svelte:head>


{#if showSuccess}
  <div class="text-center py-8">
    <div class="inline-flex items-center justify-center w-16 h-16 mb-4 rounded-full bg-green-100 text-green-500">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    </div>
    <h3 class="text-lg font-medium" style="color: {currentColors.headingColor}">
      {profile ? 'Profile updated successfully!' : 'Profile created successfully!'}
    </h3>
  </div>
{:else}
  {#if profile && !isEditMode}
    <div class="relative max-w-3xl mx-auto rounded-lg mt-10 p-6 flex flex-col sm:flex-row items-center sm:items-start space-y-6 sm:space-y-0 sm:space-x-8" 
         style="background-color: {currentColors.cardBg}; 
                color: {currentColors.color};
                border: 1px solid {currentColors.borderColor};
                box-shadow: {currentColors.shadowLight}">
      
      <button
        on:click={() => isEditMode = true}
        aria-label="Edit Profile"
        class="absolute top-4 right-4 p-1 rounded-full hover:bg-opacity-20 transition"
        style="color: {currentColors.colorMuted}; background-color: {currentTheme === 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)'}"
        title="Edit Profile"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536M16.5 3.75a2.25 2.25 0 013.182 3.182L7.5 18.75H4.5v-3l12-12z" />
        </svg>
      </button>

      {#if profileImageUrl}
        <div class="flex-shrink-0">
          <img 
            src={URL.createObjectURL(new Blob(profileImageUrl))} 
            alt="Profile Image" 
            class="w-28 h-28 rounded-full object-cover border-4 shadow-sm"
            style="border-color: {currentColors.accent}"
          />
        </div>
      {/if}

      <div class="flex-grow w-full grid grid-cols-1 sm:grid-cols-2 gap-y-3 gap-x-8">
        <div>
          <p class="text-xs uppercase font-semibold" style="color: {currentColors.colorMuted}">First Name</p>
          <p class="text-lg font-semibold" style="color: {currentColors.color}">{profile?.name || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold" style="color: {currentColors.colorMuted}">Last Name</p>
          <p class="text-lg font-semibold" style="color: {currentColors.color}">{profile?.surname || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold" style="color: {currentColors.colorMuted}">Address</p>
          <p class="text-lg font-medium" style="color: {currentColors.color}">{profile?.userAddress || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold" style="color: {currentColors.colorMuted}">Status</p>
          <p class="text-lg font-medium" style="color: {currentColors.color}">{profile?.status || '-'}</p>
        </div>

        <div class="col-span-1 sm:col-span-2">
          <p class="text-xs uppercase font-semibold" style="color: {currentColors.colorMuted}">Description</p>
          <p class="text-md" style="color: {currentColors.color}">{profile?.description || '-'}</p>
        </div>
      </div>
    </div>

  {:else}
    <div class="max-w-3xl mx-auto rounded-lg mt-10 p-6" 
         style="background-color: {currentColors.cardBg}; 
                color: {currentColors.color};
                border: 1px solid {currentColors.borderColor};
                box-shadow: {currentColors.shadowLight}">
      
      <h1 class="text-2xl font-semibold mb-6 text-center" style="color: {currentColors.headingColor}">
        {profile ? 'Update Profile' : 'Create Profile'}
      </h1>

      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        {#if profileImageUrl || profileImageBlob}
          <div class="flex justify-center">
            <img 
              src={profileImageBlob ? URL.createObjectURL(profileImageBlob) : URL.createObjectURL(new Blob(profileImageUrl))} 
              alt="Profile Preview" 
              class="w-32 h-32 rounded-full object-cover border-2"
              style="border-color: {currentColors.borderColor}"
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
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          />
          <label
            for="name"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
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
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          />
          <label
            for="surname"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
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
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent
                   focus:outline-none focus:ring-2 pr-10 disabled:opacity-70 disabled:cursor-not-allowed transition"
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          />
          <label
            for="address"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
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
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          />
          <label
            for="profileImage"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
          >
            Profile Image
          </label>
        </div>

        <div class="relative">
          <input
            id="status"
            type="text"
            bind:value={status}
            placeholder=" "
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          />
          <label
            for="status"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
          >
            Status
          </label>
        </div>

        <div class="relative">
          <textarea
            id="description"
            rows="3"
            bind:value={description}
            placeholder=" "
            class="peer w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent resize-none focus:outline-none focus:ring-2 transition" 
            style="background-color: {currentColors.inputBg}; 
                   color: {currentColors.color};
                   border: 1px solid {currentColors.inputBorder};
                   focus: {currentColors.inputFocus}"
          ></textarea>
          <label
            for="description"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            style="color: {currentColors.colorMuted};
                   peer-focus: {currentColors.inputFocus};
                   peer-placeholder-shown: {currentColors.colorMuted}"
          >
            Description
          </label>
        </div>

        <div class="text-center space-x-4">
         <button 
          type="submit" 
          class="submit-btn px-6 py-2 rounded-md font-medium hover:shadow-md"
          style="--btn-bg: {currentColors.btn};
                --btn-text: {currentColors.btnText};
                --btn-hover: {currentColors.btnHover}"
        >
          {profile ? 'Update' : 'Save'} Profile
        </button>
                  
          {#if profile}
            <button 
              type="button" 
              on:click={() => isEditMode = false} 
              class="px-4 py-2 rounded-md font-medium transition"
              style="background-color: {currentColors.btnSecondary}; 
                     color: {currentColors.color};
                     border: 1px solid {currentColors.borderColor}"
            >
              Cancel
            </button>
          {/if}
        </div>
      </form>
    </div>
  {/if}
{/if}

<style>
  .submit-btn {
    background-color: var(--btn-bg);
    color: var(--btn-text);
    transition: background-color 0.2s ease;
  }
  .submit-btn:hover {
    background-color: var(--btn-hover);
  }
</style>