<script>
  import { createEventDispatcher } from "svelte";
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { get } from "svelte/store";
  import Pagination from "$lib/utils/Pagination.svelte";
  import { page } from '$app/stores';
  import { authStore } from '$lib/store/auth-store'; 

  const dispatch = createEventDispatcher();
  export let selectedMessage;
  let searchTerm = "";
  let mails = [];
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;
  let currentTheme;
  let currentColors;
  let isSentPage = false;
  let error = null;
  let filteredMails = [];


 function selectMessage(msg) {
    if (!selectedMessage || msg?.id.toString() !== selectedMessage?.id.toString()) {
      dispatch('select', msg);
    }
  }

  async function getMails() {
    try {
      showLoader('Loading messages...'); 
      
      const identity = await authStore.sync();
      if (!identity?.getPrincipal) {
        throw new Error("Not authenticated");
      }

      const pageNumberOpt = [pageNumber];
      const pageSizeOpt = [pageSize];

      let mailData;
      if (isSentPage) {
        mailData = await mailsStore.fetchOutboxMails(pageNumberOpt, pageSizeOpt);
      } else {
        mailData = await mailsStore.fetchInboxMails(pageNumberOpt, pageSizeOpt);
      }

      mails = mailData?.data || [];
      hasNextPage = Number(mailData?.totalPages) > pageNumber;
    } catch (err) {
      console.error("Failed to fetch mails:", err);
      error = err;
      mails = [];
    } finally {
      hideLoader(); 
    }
  }

  function handlePageChange(newPage) {
    pageNumber = newPage;
    getMails();
  }

  onMount(async () => {
    isSentPage = $page.url.pathname.includes('/sent');
    await getMails();
  });

  $: {
    const newIsSentPage = $page.url.pathname.includes('/sent');
    if (newIsSentPage !== isSentPage) {
      isSentPage = newIsSentPage;
      getMails();
    }
  }

  $: filteredMails = searchTerm.trim()
  ? mails.filter(m => (m.subject || '').toLowerCase().includes(searchTerm.trim().toLowerCase()))
  : mails;

  $: if (searchTerm) {
  pageNumber = 1;
  }


</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen bg-white">
  <h2 class="text-2xl font-semibold mb-6 text-gray-800">
    {isSentPage ? "Sent Mails" : "Inbox Mails"}
  </h2>

  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-6 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
  />

  {#if error}
    <div class="text-red-500 text-center p-4">
      Error loading messages: {error.message}
    </div>
  {:else if filteredMails.length > 0}
    <div class="space-y-4">
      {#each filteredMails as msg, i}
        <div
          class="bg-white border border-gray-200 rounded-xl shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer p-5 flex justify-between items-center group"
          class:bg-blue-50={selectedMessage?.id === msg.id}
          on:click={() => selectMessage(msg)}
        >
          <div class="flex-1 min-w-0">
            <p class="text-base font-medium text-gray-800 truncate group-hover:text-blue-600">
              {isSentPage ? (msg?.to || `Recipient ${i + 1}`) : (msg?.from || `Sender ${i + 1}`)}
            </p>
            <p class="text-sm text-gray-600 truncate">
              {msg?.subject || 'No Subject'}
            </p>
          </div>
          <span class="text-sm text-gray-500 pl-6 shrink-0 whitespace-nowrap">
            {new Date(Number(msg?.createdOn) / 1_000_000).toLocaleString()}
          </span>
        </div>
      {/each}

      <Pagination
        currentPage={pageNumber}
        {hasNextPage}
        onPageChange={handlePageChange}
      />
    </div>
  {:else}
    <p class="text-gray-500 text-center">No messages to show.</p>
  {/if}
</div>