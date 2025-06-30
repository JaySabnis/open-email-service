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
      <div>
        <h2 class="text-2xl font-semibold text-gray-800 mb-2">
          {mailData?.subject || 'No Subject'}
        </h2>
       <div class="flex items-center gap-3 mb-2">
          {#if fromUser?.profileImage}
            <img 
              src={generateImageSrc(fromUser.profileImage)}
              alt="Profile Image"
              class="w-10 h-10 rounded-full object-cover border border-gray-300"
            />
          {/if}
          <div>
            <p class="text-sm text-gray-700 font-medium">
              {fromUser?.name || ''} {fromUser?.surname || ''}
            </p>
            <p class="text-xs text-gray-500">
              {mailData?.from || 'Unknown Sender'}
            </p>
          </div>
        </div>

        <p class="text-xs text-gray-500">
          {new Date(Number(mailData?.createdOn) / 1_000_000).toLocaleString()}
        </p>
      </div>
      <button
        on:click={close}
        class="text-gray-500 hover:text-red-600 transition text-lg font-bold px-2"
        aria-label="Close message details"
        title="Close"
      >
        ✖
      </button>
    </div>

    <div class="flex-grow bg-white rounded-lg p-6 text-sm shadow-sm whitespace-pre-line text-gray-800">
      {#if mailData?.body}
        {mailData.body}
      {:else}
        <p class="text-gray-400 italic">No mail content</p>
      {/if}
    </div>

   <div class="mt-6 flex justify-end">
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