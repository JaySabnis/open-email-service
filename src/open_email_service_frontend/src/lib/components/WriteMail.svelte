<script>
  import { createEventDispatcher } from "svelte";
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import { goto } from '$app/navigation';
  import { mailsStore } from '$lib/store/mails-store';
  import { profileStore } from '$lib/store/profile-store';
  import { generateImageSrc } from '$lib/utils/helpers';
  import { theme } from '$lib/store/theme';
  import { get } from 'svelte/store';
  const dispatch = createEventDispatcher();

  export let to = "";
  export let subject = "";
  export let message = "";
  export let minimized = false;
  export let isReply = false;
  export let parentMailId = []; 
  let toUserProfile = null;
  let profileError = null;


  let attachmentFile = null;
  let attachmentBlob = null;
  let error = null;
  let currentTheme = get(theme);

  async function send() {
    try {
      showLoader('Sending email...');
      
      let attachmentIds = [];
      if (attachmentBlob) {
        const base64String = await blobToBase64(attachmentBlob);
        attachmentIds = [base64String];
      }

      const mail = {
        to,
        subject: opt(subject),
        body: message,
        isReply,
        parentMailId,
        attachmentIds
      };

      await mailsStore.sendEmails(mail);
      
      resetForm();
      
      if (!minimized) {
        dispatch('sent');
        await goto('/sent');
      }
    } catch (err) {
      error = err;
      console.error('Error sending email:', err);
    } finally {
      hideLoader();
    }
  }

  function close() {
    dispatch("close");
  }

  function toggleMinimize() {
    minimized = !minimized;
  }

  function resetForm() {
    to = "";
    subject = "";
    message = "";
    attachmentFile = null;
    attachmentBlob = null;
    error = null;
  }

  function opt(value) {
    if (value === undefined || value === null || value === '') {
      return [];  
    }
    return [value]; 
  }

  function handleAttachmentUpload(event) {
    const file = event.target.files[0];
    if (file) {
      attachmentFile = file;
      const reader = new FileReader();
      reader.onloadend = () => {
        attachmentBlob = new Blob([reader.result], { type: file.type });
      };
      reader.readAsArrayBuffer(file);
    }
  }

  function blobToBase64(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64String = reader.result.split(',')[1]; 
        resolve(base64String);
      };
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  async function fetchToUserProfile() {
    try {
      if (!to.trim()) return;
      const profile = await profileStore.getProfileByUserAddress(to.trim());
      if (profile?.ok) {
        // console.log('Fetched profile:', profile.ok);
        toUserProfile = profile.ok;
        profileError = '';
      } else {
        profileError = 'not-registered';
        toUserProfile = null;
      }
    } catch (err) {
      profileError = 'Error fetching profile';
      toUserProfile = null;
      console.error(err);
    }
  }

  let debounceTimeout;
  $: if (to && to.includes('@')) {
    clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
      fetchToUserProfile();
    }, 500);
  }

  theme.subscribe((value) => {
  currentTheme = value;
});
</script>

<div class="flex flex-col rounded-lg shadow-lg overflow-hidden w-full max-w-md transition-all duration-300"
     class:bg-white={currentTheme === 'light'}
     class:bg-gray-800={currentTheme === 'dark'}>

  <div class="flex justify-between items-center p-4 border-b"
       class:bg-gray-50={currentTheme === 'light'}
       class:bg-gray-700={currentTheme === 'dark'}
       class:border-gray-200={currentTheme === 'light'}
       class:border-gray-600={currentTheme === 'dark'}>
    <h2 class="text-lg font-semibold"
        class:text-gray-800={currentTheme === 'light'}
        class:text-gray-100={currentTheme === 'dark'}>
      {isReply ? 'Reply' : 'New Mail'}
    </h2>

    <div class="flex space-x-2">
      <button
        aria-label={minimized ? "Expand" : "Minimize"}
        on:click={toggleMinimize}
        class="p-1.5 rounded-md transition-colors"
        class:hover:bg-gray-200={currentTheme === 'light'}
        class:hover:bg-gray-600={currentTheme === 'dark'}
        class:text-gray-600={currentTheme === 'light'}
        class:text-gray-300={currentTheme === 'dark'}>
        —
      </button>
       <button
        aria-label="Fullscreen"
        on:click={() => goto('/send')}
        class="p-1.5 rounded-md transition-colors"
        class:hover:bg-gray-200={currentTheme === 'light'}
        class:hover:bg-gray-600={currentTheme === 'dark'}
        class:text-gray-600={currentTheme === 'light'}
        class:text-gray-300={currentTheme === 'dark'}
        title="Open in fullscreen">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
        </svg>
      </button>
      <button
        aria-label="Close"
        on:click={close}
        class="p-1.5 rounded-md transition-colors"
        class:hover:bg-red-100={currentTheme === 'light'}
        class:hover:bg-red-900={currentTheme === 'dark'}
        class:text-red-600={currentTheme === 'light'}
        class:text-red-400={currentTheme === 'dark'}>
        ✕
      </button>
    </div>
  </div>

  {#if !minimized}
    <div class="p-4 space-y-4 transition-colors"
         class:text-gray-800={currentTheme === 'light'}
         class:text-gray-100={currentTheme === 'dark'}>

      {#if error}
        <div class="p-2 text-sm rounded-md"
             class:bg-red-100={currentTheme === 'light'}
             class:bg-red-900={currentTheme === 'dark'}
             class:text-red-700={currentTheme === 'light'}
             class:text-red-300={currentTheme === 'dark'}>
          Error: {error.message}
        </div>
      {/if}

      <div class="space-y-1 w-full">
        <label class="block text-sm font-medium"
               class:text-gray-700={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
          To
        </label>
        <div class="relative">
          {#if toUserProfile}
            <div class="flex items-center gap-2 px-3 py-2 border rounded-md shadow-sm text-sm"
                 class:bg-gray-50={currentTheme === 'light'}
                 class:bg-gray-700={currentTheme === 'dark'}
                 class:text-gray-800={currentTheme === 'light'}
                 class:text-gray-100={currentTheme === 'dark'}
                 class:border-gray-300={currentTheme === 'light'}
                 class:border-gray-600={currentTheme === 'dark'}>
              {#if toUserProfile.profileImage}
                <img src={generateImageSrc(toUserProfile.profileImage)}
                     alt="User Avatar"
                     class="w-8 h-8 rounded-full object-cover" />
              {/if}
              <div class="flex flex-col">
                <span class="font-medium">{toUserProfile.name} {toUserProfile.surname}</span>
                <span class="text-xs text-gray-500 lowercase">&lt;{to}&gt;</span>
              </div>
              <button on:click={() => { toUserProfile = null; to = '' }}
                      title="Clear"
                      class="ml-auto text-xs"
                      class:text-gray-500={true}
                      class:hover:text-red-500={true}>
                ✕
              </button>
            </div>
          {:else}
            <input
              type="email"
              bind:value={to}
              placeholder="recipient@example.com"
              on:blur={fetchToUserProfile}
              class="w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
                    {currentTheme === 'light' ? 'bg-white text-gray-800 border-gray-300 placeholder-gray-400' : ''}
                    {currentTheme === 'dark' ? 'bg-gray-700 text-gray-100 border-gray-600 placeholder-gray-300' : ''}"
              required />
          {/if}
        </div>
        {#if profileError}
          <div class="text-sm mt-1 text-red-500">
            ⚠️ {profileError === 'not-registered'
              ? 'This email is not registered with our service.'
              : profileError}
          </div>
        {/if}
      </div>

      <div class="space-y-1">
        <label class="block text-sm font-medium"
              class:text-gray-700={currentTheme === 'light'}
              class:text-gray-300={currentTheme === 'dark'}>
          Subject
        </label>
        <input
          type="text"
          bind:value={subject}
          placeholder="Subject"
          class="w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
                {currentTheme === 'light' ? 'bg-white text-gray-800 border-gray-300 placeholder-gray-400' : ''}
                {currentTheme === 'dark' ? 'bg-gray-700 text-gray-100 border-gray-600 placeholder-gray-300' : ''}"
          required />
      </div>

      <div class="space-y-1">
        <label class="block text-sm font-medium"
               class:text-gray-700={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
          Message
        </label>
        <textarea
          bind:value={message}
          placeholder="Write your message here..."
          rows="8"
          class="w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
                {currentTheme === 'light' ? 'light bg-white text-gray-800 border-gray-300' : ''}
                {currentTheme === 'dark' ? 'dark bg-gray-700 text-gray-100 border-gray-600' : ''}"
          required></textarea>
      </div>

      <div class="space-y-1">
        <label class="block text-sm font-medium"
               class:text-gray-700={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
          Attachment
        </label>
        <input
          type="file"
          on:change={handleAttachmentUpload}
          class="block w-full text-sm file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold"
          class:file:bg-blue-50={currentTheme === 'light'}
          class:file:text-blue-700={currentTheme === 'light'}
          class:hover:file:bg-blue-100={currentTheme === 'light'}
          class:file:bg-blue-900={currentTheme === 'dark'}
          class:file:text-blue-300={currentTheme === 'dark'}
          class:hover:file:bg-blue-900={currentTheme === 'dark'} />
        {#if attachmentFile}
          <div class="text-sm"
               class:text-gray-500={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
            Attached: {attachmentFile.name} ({Math.round(attachmentFile.size / 1024)} KB)
          </div>
        {/if}
      </div>

      <div class="flex justify-end space-x-3">
        <button
          type="button"
          on:click={close}
          class="px-4 py-2 text-sm font-medium border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition"
          class:bg-white={currentTheme === 'light'}
          class:text-gray-700={currentTheme === 'light'}
          class:border-gray-300={currentTheme === 'light'}
          class:hover:bg-gray-50={currentTheme === 'light'}
          class:bg-gray-700={currentTheme === 'dark'}
          class:text-gray-300={currentTheme === 'dark'}
          class:border-gray-600={currentTheme === 'dark'}
          class:hover:bg-gray-600={currentTheme === 'dark'}>
          Cancel
        </button>
        <button
          on:click={send}
          class="px-4 py-2 text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition"
          class:bg-blue-600={true}
          class:hover:bg-blue-700={true}
          class:text-white={true}>
          Send
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  textarea.light::placeholder {
    color: #9ca3af; 
  }
  
  textarea.dark::placeholder {
    color: #d1d5db; 
  }
</style>
