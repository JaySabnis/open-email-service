<script>
  import { mailsStore } from "$lib/store/mails-store";
  import { theme } from '$lib/store/theme';
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
  let currentTheme = get(theme);


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


  theme.subscribe((value) => {
    currentTheme = value;
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

  <h1 class="text-2xl font-semibold mb-6 text-center"
      class:text-gray-800={currentTheme === 'light'}
      class:text-gray-200={currentTheme === 'dark'}>
    Send Email
  </h1>

  <form on:submit|preventDefault={handleSendMail} class="space-y-6">
    <div>
      <label for="to" class="block text-sm font-medium mb-1"
             class:text-gray-700={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
        To
      </label>
      <input
        id="to"
        bind:value={to}
        class="w-full px-3 py-2 rounded-md"
        placeholder="recipient@example.com"
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
      <label for="subject" class="block text-sm font-medium mb-1"
             class:text-gray-700={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
        Subject
      </label>
      <input
        id="subject"
        type="text"
        bind:value={subject}
        class="w-full px-3 py-2 rounded-md"
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
        class="w-full px-3 py-2 rounded-md"
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

    <div>
      <label for="attachment" class="block text-sm font-medium mb-1"
             class:text-gray-700={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
        Attachment (Optional)
      </label>
      <input
        id="attachment"
        type="file"
        accept="*/*"
        on:change={handleAttachmentUpload}
        class="w-full px-3 py-2 rounded-md"
        class:border-gray-300={currentTheme === 'light'}
        class:border-gray-600={currentTheme === 'dark'}
        class:bg-white={currentTheme === 'light'}
        class:bg-gray-700={currentTheme === 'dark'}
        class:text-gray-800={currentTheme === 'light'}
        class:text-gray-200={currentTheme === 'dark'}
      />
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
