<script>
  import { goto } from '$app/navigation';
  import { toggleWriteMail } from '$lib/store/ui';
  import { signOut } from "$lib/services/auth.services";
  import { onMount } from 'svelte';
  import { generateImageSrc } from '$lib/utils/helpers';
  export let profile;

  let currentTheme;

  function setTheme(theme) {
    currentTheme = theme;
  }

  async function logout() {
    try {
      await signOut();
      window.location.href = '/';
    } catch (error) {
      console.error("Logout failed:", error);
    }
  }

  function handleWriteClick() {
    toggleWriteMail();
  }

  onMount(() => {
    // console.log("Sidebar mounted",profile);
  });
</script>

<aside class="w-64 h-screen bg-gray-800 text-white fixed top-0 left-0 shadow-lg flex flex-col justify-between">
  <div>
    <a href="/profile" class="block hover:bg-gray-700 p-2 rounded">
      <div class="p-4 flex items-center space-x-4 border-b border-gray-700">
        <img src={generateImageSrc(profile?.profileImage)} alt="Profile" class="w-12 h-12 rounded-full" />
        <div>
          <div class="text-sm font-semibold">{profile?.name || "User"}</div>
          <div class="text-xs text-gray-400 truncate">{profile?.userAddress || "user@example.com"}</div>
        </div>
      </div>
    </a>

    <nav class="p-4 space-y-2">
      <button
        class="flex items-center gap-2 w-full hover:bg-gray-700 p-2 rounded text-left focus:outline-none"
        on:click={handleWriteClick}
        aria-label="Write new mail"
      >
        <span class="text-lg font-bold">+</span> Write
      </button>

      <a href="/home" class="block hover:bg-gray-700 p-2 rounded">Home</a>
      <a href="/send" class="block hover:bg-gray-700 p-2 rounded">Send</a>
      <a href="/sent" class="block hover:bg-gray-700 p-2 rounded">Sent</a>
    </nav>
  </div>

  <div class="p-4 space-y-2">
    <div class="flex rounded-md bg-gray-200 dark:bg-gray-700 overflow-hidden border border-gray-300 dark:border-gray-600">
      <button
        class="flex-1 py-1.5 text-sm flex items-center justify-center gap-1 transition-all duration-200 hover:bg-gray-300 dark:hover:bg-gray-600 focus:outline-none font-medium rounded-l-md"
        class:bg-white={currentTheme === 'light'}
        class:text-black={currentTheme === 'light'}
        on:click={() => setTheme("light")}
      >
        ☀️ Light
      </button>

      <button
        class="flex-1 py-1.5 text-sm flex items-center justify-center gap-1 transition-all duration-200 hover:bg-gray-300 dark:hover:bg-gray-600 focus:outline-none font-medium rounded-r-md"
        class:bg-white={currentTheme === 'dark'}
        class:text-black={currentTheme === 'dark'}
        on:click={() => setTheme("dark")}
      >
        🌙 Dark
      </button>
    </div>

    <button
      on:click={logout}
      class="w-full py-2 mt-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md transition-all duration-200"
    >
      🔓 Logout
    </button>
  </div>
</aside>
