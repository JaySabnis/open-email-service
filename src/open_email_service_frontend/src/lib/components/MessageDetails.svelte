<script>
  import { mailsStore } from '$lib/store/mails-store';
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import WriteMail from './WriteMail.svelte'; 
  import {profileStore} from '$lib/store/profile-store'
  import { generateImageSrc } from '$lib/utils/helpers';
  export let message;

  const dispatch = createEventDispatcher();
  let currentTheme;
  let currentColors;
  let mailData;
  let error = null;
  let showReplyModal = false; 
  let fromUser = null;

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

</script>

<div 
  class="p-6 h-screen overflow-y-auto flex flex-col bg-white"
  style="background-color: {currentColors?.cardBg || '#fff'}; color: {currentColors?.color || '#000'}"
>
  {#if error}
    <div class="flex-grow flex items-center justify-center text-red-500 text-lg font-medium">
      Failed to load message: {error.message}
    </div>
  {:else}
    <div class="flex justify-between items-start mb-4">
      <h2 class="text-2xl font-semibold text-gray-800 ml-[3.5rem]">
        {mailData?.subject || 'No Subject'}
      </h2>
      <button
        on:click={close}
        class="text-gray-500 hover:text-red-600 transition text-lg font-bold px-2"
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
            class="w-12 h-12 rounded-full object-cover border border-gray-300 mt-1"
          />
        {/if}
      </div>

      <div class="flex-1 flex justify-between">
        <div>
          <div class="flex items-center flex-wrap gap-2 mb-1">
            <p class="text-sm text-gray-700 font-medium">
              {fromUser?.name || ''} {fromUser?.surname || ''}
            </p>
            <p class="text-xs text-gray-500 lowercase">
              &lt;{mailData?.from || 'unknown@domain.com'}&gt;
            </p>
          </div>
          <p class="text-xs text-gray-500 mb-1">
            To: {mailData?.to || 'N/A'}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <p class="text-xs text-gray-500 whitespace-nowrap">
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

    <div class="flex-1 bg-white rounded-lg p-6 text-sm shadow-sm whitespace-pre-line text-gray-800 ml-[3.5rem]">
      {#if mailData?.body}
        {mailData.body}
      {:else}
        <p class="text-gray-400 italic">No mail content</p>
      {/if}
    </div>

    <div class="mt-4 flex justify-end ml-[3.5rem]">
      <button
        on:click={handleReply}
        class="px-5 py-2 rounded-full font-medium transition bg-blue-600 text-white hover:bg-blue-700 shadow-md flex items-center gap-2"
      >
        Reply →
      </button>
    </div>
    

    {#if showReplyModal && mailData}
      <div class="fixed inset-0 bg-gray-900/70 backdrop-blur-sm flex items-center justify-center p-4 z-50">
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