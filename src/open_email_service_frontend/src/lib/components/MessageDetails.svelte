<script>
  import { mailsStore } from '$lib/store/mails-store';
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import WriteMail from './WriteMail.svelte'; 
  import {profileStore} from '$lib/store/profile-store'
  import { generateImageSrc } from '$lib/utils/helpers';
  import { theme } from "$lib/store/theme";
  import { get } from 'svelte/store';
  export let message;

  const dispatch = createEventDispatcher();
  let mailData;
  let error = null;
  let showReplyModal = false; 
  let fromUser = null;
  let currentTheme = get(theme);

  function close() {
    dispatch('close');
  }

  function handleReply() {
    showReplyModal = true;
  }

  function handleSendReply(event) {
    console.log('Replying with:', event.detail);
    showReplyModal = false;
  }

  async function getMail() {
    try {
      showLoader('Loading message...');
      error = null;
      const mail = await mailsStore.getMailById(message.id);
      
      if (mail) {
        message = mail;
        mailData = mail?.ok?.[0];
        console.log(mail,"maildata")
        const fromUserResponse = await profileStore.getProfileByUserAddress(mailData.from);
        fromUser = fromUserResponse?.ok || null;

        console.log(fromUser,"fromuser data")
      } else {
        throw new Error('Mail not found');
      }
    } catch (err) {
      error = err;
      console.error('Error fetching mail:', err);
    } finally {
      hideLoader();
    }
  }

  let lastMessageId = null;

  $: if (message?.id && message.id !== lastMessageId) {
    lastMessageId = message.id;
    getMail();
  }

   theme.subscribe((value) => {
    currentTheme = value;
  });
</script>

<div 
  class="p-6 h-screen overflow-y-auto flex flex-col"
  class:bg-white={currentTheme === 'light'}
  class:bg-gray-900={currentTheme === 'dark'}
>
  {#if error}
    <div class="flex-grow flex items-center justify-center text-red-500 text-lg font-medium">
      Failed to load message: {error.message}
    </div>
  {:else}
    <div class="flex justify-between items-start mb-4">
      <h2 class="text-2xl font-semibold ml-[3.5rem]"
          class:text-gray-800={currentTheme === 'light'}
          class:text-gray-200={currentTheme === 'dark'}>
        {mailData?.subject || 'No Subject'}
      </h2>
      <button
        on:click={close}
        class="transition text-lg font-bold px-2"
        class:text-gray-500={currentTheme === 'light'}
        class:text-gray-400={currentTheme === 'dark'}
        class:hover:text-red-600={currentTheme === 'light'}
        class:hover:text-red-500={currentTheme === 'dark'}
        aria-label="Close message details"
        title="Close"
      >
        ✖
      </button>
    </div>

    <div class="flex gap-4 mb-4">
      <div class="w-14 flex-shrink-0">
        {#if fromUser?.profileImage}
          <img 
            src={generateImageSrc(fromUser.profileImage)}
            alt="Profile Image"
            class="w-12 h-12 rounded-full object-cover border mt-1"
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
          />
        {/if}
      </div>

      <div class="flex-1 flex justify-between">
        <div>
          <div class="flex items-center flex-wrap gap-2 mb-1">
            <p class="text-sm font-medium"
               class:text-gray-700={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
              {fromUser?.name || ''} {fromUser?.surname || ''}
            </p>
            <p class="text-xs lowercase"
               class:text-gray-500={currentTheme === 'light'}
               class:text-gray-400={currentTheme === 'dark'}>
              &lt;{mailData?.from || 'unknown@domain.com'}&gt;
            </p>
          </div>
          <p class="text-xs mb-1"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>
            To: {mailData?.to || 'N/A'}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <p class="text-xs whitespace-nowrap"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>
            {new Date(Number(mailData?.createdOn) / 1_000_000).toLocaleString()}
          </p>
          {#if mailData?.starred}
            <span title="Starred" class="text-yellow-500 text-xl">★</span>
          {:else}
            <span title="Not Starred" class="text-yellow-500 text-xl">☆</span>
          {/if}
        </div>
      </div>
    </div>

    <div class="flex-1 rounded-lg p-6 text-sm shadow-sm whitespace-pre-line ml-[3.5rem]"
         class:bg-white={currentTheme === 'light'}
         class:bg-gray-800={currentTheme === 'dark'}
         class:text-gray-800={currentTheme === 'light'}
         class:text-gray-200={currentTheme === 'dark'}>
      {#if mailData?.body}
        {mailData.body}
      {:else}
        <p class="italic"
           class:text-gray-400={currentTheme === 'light'}
           class:text-gray-500={currentTheme === 'dark'}>
          No mail content
        </p>
      {/if}
    </div>

    <div class="mt-4 flex justify-end ml-[3.5rem]">
      <button
        on:click={handleReply}
        class="px-5 py-2 rounded-full font-medium transition text-white shadow-md flex items-center gap-2"
        class:bg-blue-600={currentTheme === 'light'}
        class:bg-blue-500={currentTheme === 'dark'}
        class:hover:bg-blue-700={currentTheme === 'light'}
        class:hover:bg-blue-600={currentTheme === 'dark'}
      >
        Reply →
      </button>
    </div>
    

    {#if showReplyModal && mailData}
      <div class="fixed inset-0 flex items-center justify-center p-4 z-50"
           class:bg-gray-900={currentTheme === 'light'}
           class:bg-gray-950={currentTheme === 'dark'}>
        <WriteMail 
          to={mailData.from} 
          subject={`Re: ${mailData.subject || ''}`} 
          message={`\n\n---------- Original Message ----------\nFrom: ${mailData.from || ''}\nDate: ${new Date(Number(mailData.createdOn) / 1_000_000).toLocaleString()}\n\n${mailData.body || ''}`}
          on:close={() => showReplyModal = false}
          on:send={handleSendReply}
        />
      </div>
    {/if}
  {/if}
</div>