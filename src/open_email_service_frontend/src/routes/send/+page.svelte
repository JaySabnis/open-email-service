<script>
  import { mailsStore } from "$lib/store/mails-store";
  import { theme } from '$lib/store/theme';
  import { onDestroy,onMount } from 'svelte';
  import { get } from 'svelte/store';
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { goto } from '$app/navigation';
  import { faArrowLeft } from '@fortawesome/free-solid-svg-icons'
  import { FontAwesomeIcon } from '@fortawesome/svelte-fontawesome'
  import { generateImageSrc } from '$lib/utils/helpers';  
  import { profileStore } from '$lib/store/profile-store';

  let to = "";
  let subject = "";
  let body = "";
  let attachments = []; 
  let attachmentFile = null;
  let attachmentBlob = null;
  let currentTheme = get(theme);
  let profileError = null;
  let toUserProfile = null;
  let attachmentId = null;
  let uploadProgress = 0;
  let uploadComplete = false;
  let progressInterval;
  let isUploading = false;
  let parentMailId = null; 
  let fileSizeError = false;
  let isEditMode = false;
  let messageId = null;

   async function handleSendMail() {
    if (isUploading) {
      error = { message: 'Please wait for attachment to finish uploading' };
      return;
    }
    
    try {
      showLoader('Sending email...');
      const mail = {
        to,
        subject: opt(subject),
        body: body,
        isReply: false,
        parentMailId: opt(parentMailId),
        attachmentIds: attachmentId ? [attachmentId] : []
      };
      console.log("mail data:", mail);

      await mailsStore.sendEmails(mail);
      
      // Reset form
      to = "";
      subject = "";
      body = "";
      attachmentFile = null;
      attachmentBlob = null;
      sessionStorage.removeItem('emailDraft');
      
      await goto(isEditMode ? '/sent' : '/sent');
    } catch (error) {
      console.error('Error sending email:', error);
    } finally {
      hideLoader(); 
    }
  }

  function opt(value) {
    if (value === undefined || value === null || value === '') {
      return [];  
    }
    return [value]; 
  }

  async function handleAttachmentUpload(event) {
    const MAX_SIZE = 1.5 * 1024 * 1024;
    const file = event.target.files[0];
    if (!file) return;

    if (file.size > MAX_SIZE) {
    fileSizeError = true;
    return;
    }

    fileSizeError = false;
    attachmentFile = file;
    attachmentId = null;
    isUploading = true;
    uploadComplete = false;
    uploadProgress = 0;

    progressInterval = setInterval(() => {
      if (uploadProgress < 90) {
        uploadProgress += 10;
      } else if (uploadProgress < 95) {
        uploadProgress += 1;
      } else if (uploadProgress < 99) {
        uploadProgress += 0.5;
      }
    }, 300);

    try {
      const arrayBuffer = await file.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);
      
      const fileData = {
        filedata: Array.from(uint8Array),
        fileName: file.name,
        contentType: file.type,
        fileSize: file.size
      };

      const result = await mailsStore.uploadFile(fileData);
      
      uploadProgress = 100;
      await new Promise(resolve => setTimeout(resolve, 300)); 
      
      if (result?.ok?.fileId) {
        attachmentId = result.ok.fileId;
        uploadComplete = true;
      } else {
        throw new Error('Upload failed - no ID returned');
      }
    } catch (err) {
      console.error('Upload error:', err);
      attachmentFile = null;
      error = err;
    } finally {
      clearInterval(progressInterval);
      isUploading = false;
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

   onMount(async () => {
      const savedDraft = sessionStorage.getItem('emailDraft');
      if (savedDraft) {
        try {
          const draft = JSON.parse(savedDraft);
          to = draft.to || '';
          subject = draft.subject || '';
          sessionStorage.removeItem('emailDraft');
        } catch (err) {
          console.error('Failed to parse saved draft:', err);
        }
    }

  });

</script>

<style>
  input:focus, textarea:focus {
    outline: none;
    box-shadow: 0 0 0 3px var(--input-focus-color);
  }

  button:hover {
    cursor: pointer;
  }
</style>


<svelte:head>
  <title>Open Mail | Send Mails</title>
</svelte:head>


<div class="max-w-xl mx-auto p-6 mt-10 rounded-lg shadow-lg"
     class:bg-white={currentTheme === 'light'}
     class:bg-gray-800={currentTheme === 'dark'}>

     <div class="mb-4">
      <button
        type="button"
        on:click={() => history.back()}
        class="flex items-center gap-2 text-sm font-medium transition-colors"
        class:text-gray-700={currentTheme === 'light'}
        class:text-gray-300={currentTheme === 'dark'}
        class:hover:text-blue-600={currentTheme === 'light'}
        class:hover:text-blue-400={currentTheme === 'dark'}
      >
        <FontAwesomeIcon icon={faArrowLeft} class="h-4 w-4" />
        Back
      </button>
    </div>

  <h1 class="text-2xl font-semibold mb-6 text-center"
      class:text-gray-800={currentTheme === 'light'}
      class:text-gray-200={currentTheme === 'dark'}>
    Send Email
  </h1>

  <form on:submit|preventDefault={handleSendMail} class="space-y-6">
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

    <div>
      <label for="subject" class="block text-sm font-medium mb-1"
             class:text-gray-700={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
        Subject
      </label>
      <input
        id="subject"
        type="text"
        bind:value={subject}
        class="w-full px-3 py-2 rounded-md border"
        placeholder="Email subject"
        required
        class:border-gray-300={currentTheme === 'light'}
        class:border-gray-600={currentTheme === 'dark'}
        class:bg-white={currentTheme === 'light'}
        class:bg-gray-700={currentTheme === 'dark'}
        class:text-gray-800={currentTheme === 'light'}
        class:text-gray-200={currentTheme === 'dark'}
        class:focus:ring-blue-500={currentTheme === 'light'}
        class:focus:ring-blue-400={currentTheme === 'dark'}
        class:focus:border-blue-500={currentTheme === 'light'}
        class:focus:border-blue-400={currentTheme === 'dark'}
      />
    </div>

    <div>
      <label for="body" class="block text-sm font-medium mb-1"
             class:text-gray-700={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
        Body
      </label>
      <textarea
        id="body"
        rows="5"
        bind:value={body}
        class="w-full px-3 py-2 rounded-md border"
        placeholder="Write your message here..."
        required
        class:border-gray-300={currentTheme === 'light'}
        class:border-gray-600={currentTheme === 'dark'}
        class:bg-white={currentTheme === 'light'}
        class:bg-gray-700={currentTheme === 'dark'}
        class:text-gray-800={currentTheme === 'light'}
        class:text-gray-200={currentTheme === 'dark'}
        class:focus:ring-blue-500={currentTheme === 'light'}
        class:focus:ring-blue-400={currentTheme === 'dark'}
        class:focus:border-blue-500={currentTheme === 'light'}
        class:focus:border-blue-400={currentTheme === 'dark'}
      ></textarea>
    </div>

<div class="space-y-1">
  <div class="flex justify-between items-center">
    <label class="block text-sm font-medium"
           class:text-gray-700={currentTheme === 'light'}
           class:text-gray-300={currentTheme === 'dark'}>
      Attachment
    </label>
    <span class="text-xs"
          class:text-gray-500={currentTheme === 'light'}
          class:text-gray-400={currentTheme === 'dark'}>
      Max 1.5MB
    </span>
  </div>

  <input
    type="file"
    on:change={handleAttachmentUpload}
    class="block w-full text-sm file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold"
    class:file:bg-blue-50={currentTheme === 'light'}
    class:file:text-blue-700={currentTheme === 'light'}
    class:hover:file:bg-blue-100={currentTheme === 'light'}
    class:file:bg-blue-900={currentTheme === 'dark'}
    class:file:text-blue-300={currentTheme === 'dark'}
    class:hover:file:bg-blue-900={currentTheme === 'dark'} 
    disabled={isUploading} />

  {#if isUploading}
    <div class="w-full bg-gray-200 rounded-full h-2.5 mt-2"
         class:bg-gray-700={currentTheme === 'dark'}>
      <div class="bg-blue-600 h-2.5 rounded-full transition-all duration-300" 
           style={`width: ${uploadProgress}%`}></div>
    </div>
  {:else if attachmentFile && uploadComplete}
    <div class="flex items-center justify-between text-sm mt-2"
         class:text-gray-500={currentTheme === 'light'}
         class:text-gray-300={currentTheme === 'dark'}>
      <span>
        Attached: {attachmentFile.name} ({Math.round(attachmentFile.size / 1024)} KB)
      </span>
      <button on:click={() => {
        attachmentFile = null;
        attachmentId = null;
        uploadComplete = false;
      }} class="text-red-500 hover:text-red-700">
        ✕
      </button>
    </div>
  {/if}

  {#if fileSizeError}
    <div class="text-red-500 text-xs mt-1">
      ⚠️ File exceeds 1.5MB limit
    </div>
  {/if}
</div>

    <div class="text-center">
      <button
        type="submit"
        class="px-4 py-2 font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors"
        class:bg-blue-600={currentTheme === 'light'}
        class:bg-blue-500={currentTheme === 'dark'}
        class:hover:bg-blue-700={currentTheme === 'light'}
        class:hover:bg-blue-600={currentTheme === 'dark'}
        class:focus:ring-blue-500={currentTheme === 'light'}
        class:focus:ring-blue-400={currentTheme === 'dark'}
        class:text-white={true}
      >
        Send Email
      </button>
    </div>
  </form>
</div>
