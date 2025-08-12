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
  import { generateImageSrc } from '$lib/utils/helpers';
  import ConfirmationDialogue from '$lib/components/ConfirmationDialogue.svelte';
  
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
  let fullAddress = "";
  const suffix = "@openmail";
  let showDeleteConfirmation = false;
  let isDeleting = false;

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
          userAddress: fullAddress,
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

  async function deleteProfile() {
    isDeleting = true;
    try {
      await profileStore.deleteProfile();

      showSuccess = true;
      await logout();
    } catch (error) {
      console.error('Error deleting profile:', error);
      error = { message: 'Failed to delete profile' };
    } finally {
      isDeleting = false;
      showDeleteConfirmation = false;
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
    const raw = event.target.value;
    userAddress = raw.replace(/\s/g, ''); 
    addressValid = null;
    addressError = '';
    fullAddress = '';

    clearTimeout(addressTimer);
    addressTimer = setTimeout(validateAddress, 500);
  }

  function validateFormat(value) {
    return /^[a-zA-Z0-9._]+$/.test(value);
  }

  async function validateAddress() {
    if (!userAddress.trim()) return;

    if (!validateFormat(userAddress)) {
      addressValid = false;
      addressError = "Invalid format: Only letters, numbers, '.', and '_' allowed";
      return;
    }

    try {
      const userAddressAvailable = await profileStore.isUserAddressAvailable(userAddress + suffix);
      addressValid = userAddressAvailable;
      addressError = userAddressAvailable ? '' : 'Address not available';
      fullAddress = userAddress + suffix;
    } catch (err) {
      addressValid = false;
      addressError = 'Validation error';
      console.error(err);
    }
  }

  async function logout() {
    try {
      await signOut();
      window.location.href = '/';
    } catch (error) {
      console.error("Logout failed:", error);
    }
  }

  onDestroy(() => {
    unsubscribeTheme();
  });
</script>



<svelte:head>
  <title>Open Mail | Profile</title>
</svelte:head>


{#if showSuccess}
  <div class="text-center py-8">
    <div class="inline-flex items-center justify-center w-16 h-16 mb-4 rounded-full"
         class:bg-green-100={currentTheme === 'light'}
         class:bg-green-900={currentTheme === 'dark'}
         class:text-green-500={currentTheme === 'light'}
         class:text-green-400={currentTheme === 'dark'}>
      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    </div>
    <h3 class="text-lg font-medium"
        class:text-gray-900={currentTheme === 'light'}
        class:text-gray-100={currentTheme === 'dark'}>
      {profile ? 'Profile updated successfully!' : 'Profile created successfully!'}
    </h3>
  </div>
{:else}
  {#if profile && !isEditMode}
    <div class="relative max-w-3xl mx-auto rounded-lg mt-10 p-6 flex flex-col sm:flex-row items-center sm:items-start space-y-6 sm:space-y-0 sm:space-x-8"
         class:bg-white={currentTheme === 'light'}
         class:bg-gray-800={currentTheme === 'dark'}
         class:border-gray-200={currentTheme === 'light'}
         class:border-gray-700={currentTheme === 'dark'}
         class:shadow={currentTheme === 'light'}
         class:shadow-lg={currentTheme === 'dark'}>
      
      <button
        on:click={() => isEditMode = true}
        aria-label="Edit Profile"
        class="absolute top-4 right-4 p-1 rounded-full hover:bg-opacity-20 transition"
        class:hover:bg-gray-200={currentTheme === 'light'}
        class:hover:bg-gray-700={currentTheme === 'dark'}
        title="Edit Profile"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536M16.5 3.75a2.25 2.25 0 013.182 3.182L7.5 18.75H4.5v-3l12-12z" />
        </svg>
      </button>

      <button
      on:click|stopPropagation={() => showDeleteConfirmation = true}
      aria-label="Delete Profile"
      class="absolute top-4 right-16 p-1 rounded-full hover:bg-opacity-20 transition"
      class:hover:bg-gray-200={currentTheme === 'light'}
      class:hover:bg-gray-700={currentTheme === 'dark'}
      class:text-red-500={true}
      title="Delete Profile"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
      </svg>
    </button>

      {#if profileImageUrl}
        <div class="flex-shrink-0">
          <img 
            src={generateImageSrc(profileImageUrl)} 
            alt="Profile Image" 
            class="w-28 h-28 rounded-full object-cover border-4 shadow-sm"
            class:border-blue-500={currentTheme === 'light'}
            class:border-blue-600={currentTheme === 'dark'}/>
        </div>
      {/if}

      {#if showDeleteConfirmation}
        <ConfirmationDialogue
          title="Delete Profile"
          message="Are you sure you want to delete your profile? All your data will be permanently removed."
          confirmText={isDeleting ? 'Deleting...' : 'Delete'}
          on:confirm={deleteProfile}
          on:cancel={() => showDeleteConfirmation = false}
          confirmClass="bg-red-500 hover:bg-red-600 text-white"
          disabled={isDeleting}
        />
      {/if}

      <div class="flex-grow w-full grid grid-cols-1 sm:grid-cols-2 gap-y-3 gap-x-8">
        <div>
          <p class="text-xs uppercase font-semibold"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>First Name</p>
          <p class="text-lg font-semibold"
             class:text-gray-900={currentTheme === 'light'}
             class:text-gray-100={currentTheme === 'dark'}>{profile?.name || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>Last Name</p>
          <p class="text-lg font-semibold"
             class:text-gray-900={currentTheme === 'light'}
             class:text-gray-100={currentTheme === 'dark'}>{profile?.surname || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>Email Address</p>
          <p class="text-lg font-medium"
             class:text-gray-900={currentTheme === 'light'}
             class:text-gray-100={currentTheme === 'dark'}>{profile?.userAddress || '-'}</p>
        </div>

        <div>
          <p class="text-xs uppercase font-semibold"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>Status</p>
          <p class="text-lg font-medium"
             class:text-gray-900={currentTheme === 'light'}
             class:text-gray-100={currentTheme === 'dark'}>{profile?.status || '-'}</p>
        </div>

        <div class="col-span-1 sm:col-span-2">
          <p class="text-xs uppercase font-semibold"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>Description</p>
          <p class="text-md font-medium"
             class:text-gray-900={currentTheme === 'light'}
             class:text-gray-100={currentTheme === 'dark'}>{profile?.description || '-'}</p>
        </div>
      </div>
    </div>

  {:else}
    <div class="max-w-3xl mx-auto rounded-lg mt-10 p-6"
         class:bg-white={currentTheme === 'light'}
         class:bg-gray-800={currentTheme === 'dark'}
         class:border-gray-200={currentTheme === 'light'}
         class:border-gray-700={currentTheme === 'dark'}
         class:shadow={currentTheme === 'light'}
         class:shadow-lg={currentTheme === 'dark'}>
      
      <h1 class="text-2xl font-semibold mb-6 text-center"
          class:text-gray-900={currentTheme === 'light'}
          class:text-gray-100={currentTheme === 'dark'}>
        {profile ? 'Update Profile' : 'Create Profile'}
      </h1>

      <form on:submit|preventDefault={handleSubmit} class="space-y-6">
        {#if profileImageUrl || profileImageBlob}
          <div class="flex justify-center">
            <img 
              src={profileImageBlob ? generateImageSrc(profileImageBlob) : generateImageSrc(profileImageUrl)} 
              alt="Profile Preview" 
              class="w-32 h-32 rounded-full object-cover border-2"
              class:border-gray-200={currentTheme === 'light'}
              class:border-gray-700={currentTheme === 'dark'}/>
          </div>
        {/if}

        <div class="relative">
          <input
            id="name"
            type="text"
            bind:value={name}
            placeholder=" "
            required
            class="peer w-full border rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}/>
          <label
            for="name"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
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
            class="peer w-full border rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}/>
          <label
            for="surname"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Last Name
          </label>
        </div>

        <div class="relative">
          <input
            id="address"
            type="text"
            bind:value={userAddress}
            placeholder="Mail Address"
            disabled={profile}
            on:input={onAddressInput}
            class="peer w-full border rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent
                  focus:outline-none focus:ring-2 pr-16 disabled:opacity-70 disabled:cursor-not-allowed transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}/>
            
          {#if !profile}
            <div class="absolute inset-y-0 right-10 flex items-center pointer-events-none text-lg font-medium"
                 class:text-gray-400={currentTheme === 'light'}
                 class:text-gray-500={currentTheme === 'dark'}>
              @openmail
            </div>
          {/if}

          <label
            for="address"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                  peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                  peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Mail Address
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

          {#if addressValid && fullAddress}
            <p class="text-green-600 text-sm mt-1">
              Address preview: <strong>{fullAddress}</strong>
            </p>
          {/if}
        </div>

        <div class="relative">
          <input
            id="profileImage"
            type="file"
            accept="image/*"
            on:change={handleImageUpload}
            placeholder=" "
            class="peer border w-full rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}/>
          <label
            for="profileImage"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Profile Image
          </label>
          <p class="mt-1 text-sm"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Maximum image size: 1.5MB (JPEG, PNG)
          </p>
        </div>

        <div class="relative">
          <input
            id="status"
            type="text"
            bind:value={status}
            placeholder=" "
            class="peer w-full border rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent focus:outline-none focus:ring-2 transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}/>
          <label
            for="status"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Status
          </label>
        </div>

        <div class="relative">
          <textarea
            id="description"
            rows="3"
            bind:value={description}
            placeholder=" "
            class="peer w-full border rounded-md px-4 pt-5 pb-2 text-lg font-medium placeholder-transparent resize-none focus:outline-none focus:ring-2 transition"
            class:bg-white={currentTheme === 'light'}
            class:bg-gray-700={currentTheme === 'dark'}
            class:text-gray-900={currentTheme === 'light'}
            class:text-gray-100={currentTheme === 'dark'}
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
            class:focus:ring-blue-500={true}
            class:focus:border-blue-500={true}></textarea>
          <label
            for="description"
            class="absolute left-4 top-2 text-sm pointer-events-none transition-all duration-200 origin-left
                   peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-placeholder-shown:font-normal
                   peer-focus:top-2 peer-focus:text-sm peer-focus:font-medium"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            Description
          </label>
        </div>
        
        <div class="flex flex-row items-center space-x-4 justify-center">
          <div class="text-center space-x-4">
            <button 
              type="submit" 
              class="px-4 py-2 font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors"
              class:bg-blue-600={true}
              class:hover:bg-blue-700={true}
              class:text-white={true}
              class:focus:ring-blue-500={true}>
              {profile ? 'Update' : 'Save'} Profile
            </button>         

            {#if profile}
              <button 
                type="button" 
                on:click={() => isEditMode = false} 
                class="px-4 py-2 rounded-md font-medium transition"
                class:bg-white={currentTheme === 'light'}
                class:bg-gray-700={currentTheme === 'dark'}
                class:text-gray-700={currentTheme === 'light'}
                class:text-gray-300={currentTheme === 'dark'}
                class:border-gray-300={currentTheme === 'light'}
                class:border-gray-600={currentTheme === 'dark'}
                class:hover:bg-gray-50={currentTheme === 'light'}
                class:hover:bg-gray-600={currentTheme === 'dark'}>
                Cancel
              </button>
            {/if}

            {#if !profile}
              <button 
                type="button" 
                on:click={logout}
                class="px-5 py-2 rounded-md font-medium transition"
                class:bg-white={currentTheme === 'light'}
                class:bg-gray-700={currentTheme === 'dark'}
                class:text-gray-700={currentTheme === 'light'}
                class:text-gray-300={currentTheme === 'dark'}
                class:border-gray-300={currentTheme === 'light'}
                class:border-gray-600={currentTheme === 'dark'}
                class:hover:bg-gray-50={currentTheme === 'light'}
                class:hover:bg-gray-600={currentTheme === 'dark'}>
                Logout
              </button>
            {/if}
          </div>
        </div>
      </form>
    </div>
  {/if}
{/if}