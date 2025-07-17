<script>
  import { goto } from '$app/navigation';
  import { toggleWriteMail } from '$lib/store/ui';
  import { signOut } from "$lib/services/auth.services";
  import { onMount } from 'svelte';
  import { generateImageSrc } from '$lib/utils/helpers';
  import { theme } from '$lib/store/theme'; 
  import { get } from 'svelte/store';
  import { faPlus, faInbox, faPaperPlane, faSignOutAlt } from '@fortawesome/free-solid-svg-icons'
  import { FontAwesomeIcon } from '@fortawesome/svelte-fontawesome'
  export let profile;

  let currentTheme = get(theme); 

  const setTheme = (value) => {
    theme.set(value);
    currentTheme = value;
  };

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

  const unsubscribe = theme.subscribe(value => currentTheme = value);
  onMount(() => {
    return () => unsubscribe(); 
  });
</script>

<aside class="w-64 h-screen fixed top-0 left-0 shadow-lg flex flex-col justify-between transition-colors duration-300"
       class:bg-gray-800={currentTheme === 'dark'}
       class:bg-white={currentTheme === 'light'}
       class:text-white={currentTheme === 'dark'}
       class:text-gray-800={currentTheme === 'light'}
       class:border-r={currentTheme === 'light'}
       class:border-gray-200={currentTheme === 'light'}
       class:border-gray-700={currentTheme === 'dark'}>

  <div>
    <a href="/profile" class="block p-1 rounded transition-colors hover:bg-opacity-20"
       class:hover:bg-gray-700={currentTheme === 'dark'}
       class:hover:bg-gray-100={currentTheme === 'light'}>
      <div class="p-2 flex items-center space-x-4 border-b"
           class:border-gray-700={currentTheme === 'dark'}
           class:border-gray-200={currentTheme === 'light'}>
        <img src={generateImageSrc(profile?.profileImage)} alt="Profile" class="w-12 h-12 rounded-full border-2"
             class:border-gray-600={currentTheme === 'dark'}
             class:border-gray-300={currentTheme === 'light'}/>
        <div>
          <div class="text-sm font-semibold">{profile?.name || "User"}</div>
          <div class="text-xs truncate"
               class:text-gray-400={currentTheme === 'dark'}
               class:text-gray-500={currentTheme === 'light'}>{profile?.userAddress || "user@example.com"}</div>
        </div>
      </div>
    </a>

    <nav class="p-4 space-y-2">
      <button
        class="flex items-center gap-3 w-full p-2 rounded text-left focus:outline-none transition-colors hover:bg-opacity-20"
        class:hover:bg-gray-700={currentTheme === 'dark'}
        class:hover:bg-gray-100={currentTheme === 'light'}
        on:click={handleWriteClick}
        aria-label="Write new mail"
      >
        <FontAwesomeIcon icon={faPlus} class="h-4 w-4" />
        <span>New Mail</span>
      </button>

      <a href="/home" class="flex items-center gap-3 p-2 rounded transition-colors hover:bg-opacity-20"
         class:hover:bg-gray-700={currentTheme === 'dark'}
         class:hover:bg-gray-100={currentTheme === 'light'}>
        <FontAwesomeIcon icon={faInbox} class="h-4 w-4" />
        <span>Inbox</span>
      </a>
      
      <a href="/sent" class="flex items-center gap-3 p-2 rounded transition-colors hover:bg-opacity-20"
         class:hover:bg-gray-700={currentTheme === 'dark'}
         class:hover:bg-gray-100={currentTheme === 'light'}>
        <FontAwesomeIcon icon={faPaperPlane} class="h-4 w-4" />
        <span>Sent</span>
      </a>
    </nav>
  </div>

  <div class="p-4 space-y-4">
    <button
      on:click={logout}
      class="w-full py-2 px-4 rounded-md text-sm font-medium flex items-center justify-center gap-2 transition-colors"
      class:bg-red-600={true}
      class:hover:bg-red-700={true}
      class:text-white={true}
    >
      <FontAwesomeIcon icon={faSignOutAlt} class="h-4 w-4" />
      <span>Logout</span>
    </button>
  </div>
</aside>
