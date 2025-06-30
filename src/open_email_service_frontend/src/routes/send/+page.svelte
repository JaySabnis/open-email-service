<script>
  import { mailsStore } from "$lib/store/mails-store";
  import { theme } from '$lib/store/theme.js';
  import { colors } from '$lib/store/colors.js';
  import { onDestroy } from 'svelte';
  import { get } from 'svelte/store';
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { goto } from '$app/navigation';
  
  let to = "";
  let subject = "";
  let body = "";
  let attachments = []; 
  let attachmentFile = null;
  let attachmentBlob = null;
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

  onDestroy(() => {
    unsubscribeTheme();
  });

  async function handleSendMail() {
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
        body,
        isReply: false,
        parentMailId: [],
        attachmentIds
      };

      await mailsStore.sendEmails(mail);
      
      to = "";
      subject = "";
      body = "";
      attachmentFile = null;
      attachmentBlob = null;
      
      await goto('/sent');
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


<div class="max-w-xl mx-auto p-6 mt-10 rounded-lg shadow-lg" style="background-color: {currentColors.cardBg};">
  <h1 class="text-2xl font-semibold mb-6 text-center" style="color: {currentColors.headingColor};">Send Email</h1>

  <form on:submit|preventDefault={handleSendMail} class="space-y-6">
    <div>
      <label for="to" class="block text-sm font-medium mb-1" style="color: {currentColors.color};">To</label>
      <input
        id="to"
        bind:value={to}
        class="w-full border px-3 py-2 rounded-md"
        placeholder="recipient@example.com"
        required
        style="
          border-color: {currentColors.inputBorder};
          background-color: {currentColors.inputBg};
          color: {currentColors.color};
          --input-focus-color: {currentColors.inputFocus};
        "
      />
    </div>

    <div>
      <label for="subject" class="block text-sm font-medium mb-1" style="color: {currentColors.color};">Subject</label>
      <input
        id="subject"
        type="text"
        bind:value={subject}
        class="w-full border px-3 py-2 rounded-md"
        placeholder="Email subject"
        required
        style="
          border-color: {currentColors.inputBorder};
          background-color: {currentColors.inputBg};
          color: {currentColors.color};
          --input-focus-color: {currentColors.inputFocus};
        "
      />
    </div>

    <div>
      <label for="body" class="block text-sm font-medium mb-1" style="color: {currentColors.color};">Body</label>
      <textarea
        id="body"
        rows="5"
        bind:value={body}
        class="w-full border px-3 py-2 rounded-md"
        placeholder="Write your message here..."
        required
        style="
          border-color: {currentColors.inputBorder};
          background-color: {currentColors.inputBg};
          color: {currentColors.color};
          --input-focus-color: {currentColors.inputFocus};
        "
      ></textarea>
    </div>

    <div>
      <label for="attachment" class="block text-sm font-medium mb-1" style="color: {currentColors.color};">Attachment (Optional)</label>
      <input
        id="attachment"
        type="file"
        accept="*/*"
        on:change={handleAttachmentUpload}
        class="w-full border px-3 py-2 rounded-md"
        style="
          border-color: {currentColors.inputBorder};
          background-color: {currentColors.inputBg};
          color: {currentColors.color};
          --input-focus-color: {currentColors.inputFocus};
        "
      />
    </div>


    <div class="text-center">
      <button
        type="submit"
        class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-blue-700 dark:hover:bg-blue-800 transition-colors"
      >
        Send Email
      </button>
    </div>
  </form>
</div>
