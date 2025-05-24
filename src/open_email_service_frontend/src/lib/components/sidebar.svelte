<script>
  import { signOut } from "$lib/services/auth.services";
  import { goto } from "$app/navigation";
  export let isSidebarOpen = false;
  export let toggleSidebar;

    async function handleSignOut() {
    await signOut();
    goto('/');
  }

</script>

<div
  class={`bg-gray-100 z-40 transition-transform duration-300 ease-in-out
    fixed top-[56px] left-0 h-[calc(100vh-56px)]
    ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
    md:top-0 md:h-screen md:w-64 w-[60vw]'`}
>
  <div class="flex flex-col justify-between h-full relative">
    
    {#if isSidebarOpen}
      <button
        on:click={toggleSidebar}
        class="absolute top-4 right-4 text-gray-600 hover:text-black text-2xl font-bold md:block"
        aria-label="Close Sidebar"
      >
        &times;
      </button>
    {/if}

    <div>
      <div class="flex items-center p-4 md:hidden">
        <button
          class="text-black text-xl cursor-pointer p-2 bg-gray-200 rounded-full hover:bg-gray-300"
          on:click={toggleSidebar}
          aria-label="Toggle Sidebar"
        >
          {#if isSidebarOpen}
            <span>&#8592;</span> 
          {:else}
            <span>&#8594;</span>
          {/if}
        </button>
        {#if isSidebarOpen}
          <span class="ml-2 text-black font-medium">OPEN EMAIL</span>
        {/if}
      </div>

      {#if isSidebarOpen || window.innerWidth >= 768}
        <nav class="p-4 mt-8">
          <ul class="space-y-2">
            <li>
              <a href="/" class="block py-2 px-4 rounded hover:bg-gray-200">Home</a>
            </li>
            <li>
              <a href="/profile" class="block py-2 px-4 rounded hover:bg-gray-200">Profile</a>
            </li>
          </ul>
        </nav>
      {/if}
    </div>

    <div class="p-4 border-t border-gray-300">
      <div
        on:click={handleSignOut}
        class="cursor-pointer py-2 px-4 rounded hover:bg-gray-200 text-center text-red-600 font-medium"
      >
        Logout
      </div>
    </div>
  </div>
</div>

