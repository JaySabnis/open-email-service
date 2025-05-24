<script>
  import { goto } from "$app/navigation";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from 'svelte/store';
  import {  onDestroy } from "svelte";
  export let isSidebarOpen = false;
  export let toggleSidebar;

  let currentTheme;
  let currentColors;

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
    if (typeof window !== "undefined") {
      document.documentElement.classList.toggle('dark', value === 'dark');
    }
  });

  async function handleSignOut() {
    await signOut();
    goto('/');
  }

  onDestroy(() => {
    unsubscribeTheme();
  });
</script>

<div
  class={`z-40 transition-transform duration-300 ease-in-out
    fixed top-[56px] left-0 h-[calc(100vh-56px)]
    ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
    md:top-0 md:h-screen md:w-64 w-[60vw]`}
  style="background-color: {currentColors?.bgLightColor || (currentTheme === 'dark' ? '#1E1834' : '#FFFFFF')};
         color: {currentColors?.color || (currentTheme === 'dark' ? '#F7FAFC' : '#1C143D')}"
>
  <div class="flex flex-col justify-between h-full relative">
    
    {#if isSidebarOpen}
      <button
        on:click={toggleSidebar}
        class="absolute top-4 right-4 text-2xl font-bold md:block hover:opacity-80 transition-opacity"
        style="color: {currentColors?.colorMuted || (currentTheme === 'dark' ? '#A0AEC0' : '#6B7280')}"
        aria-label="Close Sidebar"
      >
        &times;
      </button>
    {/if}

    <div>
      <div class="flex items-center p-4 md:hidden">
        {#if isSidebarOpen}
          <span class="ml-2 font-medium" style="color: {currentColors?.headingColor || (currentTheme === 'dark' ? '#EDE9FE' : '#111827')}">
            OPEN EMAIL
          </span>
        {/if}
      </div>

      {#if isSidebarOpen || (typeof window !== 'undefined' && window.innerWidth >= 768)}
        <nav class="p-4 mt-8">
          <ul class="space-y-2">
            <li>
              <a 
                href="/" 
                class="block py-2 px-4 rounded transition hover:bg-opacity-20"
                style="color: {currentColors?.color};
                       background-color: {currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(239, 233, 255, 0.2)'}"
                on:mouseenter={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.4)' : 'rgba(239, 233, 255, 0.4)'}
                on:mouseleave={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(239, 233, 255, 0.2)'}
              >
                Home
              </a>
            </li>
            <li>
              <a 
                href="/profile" 
                class="block py-2 px-4 rounded transition hover:bg-opacity-20"
                style="color: {currentColors?.color};
                       background-color: {currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(239, 233, 255, 0.2)'}"
                on:mouseenter={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.4)' : 'rgba(239, 233, 255, 0.4)'}
                on:mouseleave={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(239, 233, 255, 0.2)'}
              >
                Profile
              </a>
            </li>
          </ul>
        </nav>
      {/if}
    </div>

    <div class="p-4 border-t" style="border-color: {currentColors?.borderColor || (currentTheme === 'dark' ? '#3F3B53' : '#E5E7EB')}">
      <div
        on:click={handleSignOut}
        class="cursor-pointer py-2 px-4 rounded transition text-center font-medium hover:opacity-80"
        style="color: {currentTheme === 'dark' ? '#FECACA' : '#DC2626'};
               background-color: {currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(254, 226, 226, 0.2)'}"
        on:mouseenter={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.4)' : 'rgba(254, 226, 226, 0.4)'}
        on:mouseleave={(e) => e.currentTarget.style.backgroundColor = currentTheme === 'dark' ? 'rgba(42, 32, 69, 0.2)' : 'rgba(254, 226, 226, 0.2)'}
      >
        Logout
      </div>
    </div>
  </div>
</div>