<script>
  import { createEventDispatcher } from "svelte";
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import { goto } from '$app/navigation';
  import { mailsStore } from '$lib/store/mails-store';
  import { profileStore } from '$lib/store/profile-store';
  import { generateImageSrc } from '$lib/utils/helpers';
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


</script>

<div class="flex flex-col rounded-lg shadow-lg overflow-hidden w-full max-w-md bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
  <div class="flex justify-between items-center p-4 bg-gray-50 dark:bg-gray-700 border-b border-gray-200 dark:border-gray-600">
    <h2 class="text-lg font-semibold text-gray-800 dark:text-gray-100">
      {isReply ? 'Reply' : 'New Mail'}
    </h2>
    <div class="flex space-x-2">
      <button
        aria-label={minimized ? "Expand" : "Minimize"}
        on:click={toggleMinimize}
        class="p-1.5 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-600 dark:text-gray-300 transition-colors"
      >
      </button>
      <button
        aria-label="Close"
        on:click={close}
        class="p-1.5 rounded-md hover:bg-red-100 dark:hover:bg-red-900/50 text-red-600 dark:text-red-400 transition-colors"
      >
      </button>
    </div>
  </div>

  {#if !minimized}
    <div class="p-4 space-y-4">
      {#if error}
        <div class="p-2 bg-red-100 text-red-700 rounded-md text-sm">
          Error: {error.message}
        </div>
      {/if}
      
    <div class="space-y-1 w-full">
      <label for="to" class="block text-sm font-medium text-gray-700 dark:text-gray-300">To</label>

      <div class="relative">
        {#if toUserProfile}
          <div
            class="flex items-center gap-2 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm bg-gray-50 dark:bg-gray-700 text-sm text-gray-800 dark:text-gray-100"
          >
            {#if toUserProfile.profileImage}
              <img
                src={generateImageSrc(toUserProfile.profileImage)}
                alt="User Avatar"
                class="w-8 h-8 rounded-full object-cover"
              />
            {/if}
            <div class="flex flex-col">
              <span class="font-medium">{toUserProfile.name} {toUserProfile.surname}</span>
              <span class="text-xs text-gray-500 lowercase">&lt;{to}&gt;</span>
            </div>
            <button
              class="ml-auto text-gray-500 hover:text-red-500 text-xs"
              on:click={() => { toUserProfile = null; to = '' }}
              title="Clear"
            >
              ✕
            </button>
          </div>
        {:else}
          <input
            id="to"
            type="email"
            bind:value={to}
            placeholder="recipient@example.com"
            on:blur={fetchToUserProfile}
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-gray-100"
            required
          />
        {/if}
      </div>

      {#if profileError}
        <div class="text-sm text-red-500 mt-1">
          ⚠️ {profileError === 'not-registered' 
            ? 'This email is not registered with our service.' 
            : profileError}
        </div>
      {/if}
    </div>

      <div class="space-y-1">
        <label for="subject" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Subject</label>
        <input
          id="subject"
          type="text"
          bind:value={subject}
          placeholder="Subject"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-gray-100"
          required
        />
      </div>

      <div class="space-y-1">
        <label for="message" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Message</label>
        <textarea
          id="message"
          bind:value={message}
          placeholder="Write your message here..."
          rows="8"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-gray-100"
          required
        ></textarea>
      </div>

      <div class="space-y-1">
        <label for="attachment" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Attachment
        </label>
        <input
          id="attachment"
          type="file"
          on:change={handleAttachmentUpload}
          class="block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-md file:border-0
                file:text-sm file:font-semibold
                file:bg-blue-50 file:text-blue-700
                hover:file:bg-blue-100
                dark:file:bg-blue-900/20 dark:file:text-blue-300
                dark:hover:file:bg-blue-900/30"
        />
        {#if attachmentFile}
          <div class="text-sm text-gray-500 mt-1">
            Attached: {attachmentFile.name} ({Math.round(attachmentFile.size/1024)} KB)
          </div>
        {/if}
      </div>

      <div class="flex justify-end space-x-3">
        <button
          type="button"
          on:click={close}
          class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
        >
          Cancel
        </button>
        <button
          on:click={send}
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-blue-700 dark:hover:bg-blue-800 transition-colors"
        >
          Send
        </button>
      </div>
    </div>
  {/if}
</div>