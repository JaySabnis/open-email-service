<script lang="ts">
  export let mails = [];

  import ReplyPopup from "$lib/components/replyPopup.svelte";
  import { get } from "svelte/store";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";

  let showReplyPopup = false;
  let replyData = null;

  let currentTheme;
  let currentColors;

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

  function openReplyPopup(mail) {
    replyData = {
      to: mail.from,
      subject: `Re: ${mail.subject}`,
      body: `\n\n--- Original Message ---\n${mail.body}`,
      parentMailId: mail.id,
      attachments: mail.attachmentIds || [],
    };
    showReplyPopup = true;
  }
</script>

<div class="space-y-6">
  {#each mails as mail (mail.id)}
    <div class="w-[80vw] ml-4 pl-4 cursor-default">
      <div
        class="px-4 py-3 rounded border"
        style="
            background-color: {currentColors.cardBg};
            color: {currentColors.color};
            box-shadow: {currentColors.shadowDark};
            border-color: {currentColors.borderColor};"
        >

        <h3 class="font-semibold">{mail.subject}</h3>
        <p class="text-sm text-gray-600">From: {mail.from}</p>
        <p class="mt-2 whitespace-pre-wrap">{mail.body}</p>
        <button
          class="mt-4 px-3 py-1 rounded text-white"
          style="background-color: {currentColors.primary};"
          on:click={() => openReplyPopup(mail)}
        >
          Reply
        </button>
      </div>

      {#if showReplyPopup && replyData?.parentMailId === mail.id}
        <ReplyPopup on:close={() => (showReplyPopup = false)} {replyData} />
      {/if}

      {#if mail.children?.length > 0}
        <MailThread mails={mail.children} />
      {/if}
    </div>
  {/each}
</div>
