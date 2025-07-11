<script>
  import { createEventDispatcher } from "svelte";
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { get } from "svelte/store";
  import Pagination from "$lib/utils/Pagination.svelte";
  import { page } from '$app/stores';
  import { authStore } from '$lib/store/auth-store'; 
  import { theme } from "$lib/store/theme";

  const dispatch = createEventDispatcher();
  export let selectedMessage;
  let searchTerm = "";
  let mails = [];
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;
  let currentColors;
  let isSentPage = false;
  let error = null;
  let filteredMails = [];
  let currentTheme = get(theme);

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
      // console.log(mails,"mail")
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

  async function markAsImportant(msgId) { 
    try {
      showLoader('Marking important...'); 
      // console.log(msgId,"msgids")
      const msg = await mailsStore.markItAsImportant(msgId);
      getMails();
    // console.log(msg,"msg")
    } catch (err) {
      console.error("Failed to mark as important", error);
      error = err;
    } finally {
      hideLoader();
    }
    
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

  theme.subscribe((value) => {
    currentTheme = value;
  });

</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen"
     class:bg-white={currentTheme === 'light'}
     class:bg-gray-900={currentTheme === 'dark'}>
  
  <h2 class="text-2xl font-semibold mb-6"
      class:text-gray-800={currentTheme === 'light'}
      class:text-gray-200={currentTheme === 'dark'}>
    {isSentPage ? "Sent Mails" : "Inbox Mails"}
  </h2>

  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-6 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
    class:bg-white={currentTheme === 'light'}
    class:bg-gray-700={currentTheme === 'dark'}
    class:text-gray-800={currentTheme === 'light'}
    class:text-gray-200={currentTheme === 'dark'}
    class:border-gray-300={currentTheme === 'light'}
    class:border-gray-600={currentTheme === 'dark'}
  />

  {#if error}
    <div class="text-red-500 text-center p-4">
      Error loading messages: {error.message}
    </div>
  {:else if filteredMails.length > 0}
    <div class="space-y-4">
      {#each filteredMails as msg, i}
        <div
          class="border rounded-xl shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer p-5 flex justify-between items-center group"
          class:bg-white={currentTheme === 'light' && selectedMessage?.id !== msg.id}
          class:bg-gray-800={currentTheme === 'dark' && selectedMessage?.id !== msg.id}
          class:bg-blue-50={currentTheme === 'light' && selectedMessage?.id === msg.id}
          class:bg-blue-900={currentTheme === 'dark' && selectedMessage?.id === msg.id}
          class:border-gray-200={currentTheme === 'light'}
          class:border-gray-700={currentTheme === 'dark'}
          on:click={() => selectMessage(msg)}
        >
          <div class="flex-1 min-w-0">
            <p class="text-base font-medium truncate group-hover:text-blue-600"
               class:text-gray-800={currentTheme === 'light'}
               class:text-gray-200={currentTheme === 'dark'}>
              {isSentPage ? (msg?.to || `Recipient ${i + 1}`) : (msg?.from || `Sender ${i + 1}`)}
            </p>
            <p class="text-sm truncate"
               class:text-gray-600={currentTheme === 'light'}
               class:text-gray-400={currentTheme === 'dark'}>
              {msg?.subject || 'No Subject'}
            </p>
          </div>

          <div class="flex flex-col items-end gap-2">
            <div on:click|stopPropagation={() => markAsImportant(msg.id)} 
                 class="cursor-pointer text-yellow-500">
              {#if msg.starred}
                ★
              {:else}
                ☆
              {/if}
            </div>

            <span class="text-sm pl-6 shrink-0 whitespace-nowrap"
                  class:text-gray-500={currentTheme === 'light'}
                  class:text-gray-400={currentTheme === 'dark'}>
              {new Date(Number(msg?.createdOn) / 1_000_000).toLocaleString()}
            </span>
          </div>
        </div>
      {/each}

      <Pagination
        currentPage={pageNumber}
        {hasNextPage}
        onPageChange={handlePageChange}
      />
    </div>
  {:else}
    <p class="text-center"
       class:text-gray-500={currentTheme === 'light'}
       class:text-gray-400={currentTheme === 'dark'}>
      No mails to show.
    </p>
  {/if}
</div>