<script>
  export let currentTheme;
  export let setTheme;
  export let showSidebar;
</script>

<nav class="fixed top-0 left-0 right-0 z-50 p-4 border-b shadow-sm transition-colors duration-300"
     class:bg-white={currentTheme === 'light'}
     class:bg-gray-800={currentTheme === 'dark'}
     class:border-gray-200={currentTheme === 'light'}
     class:border-gray-700={currentTheme === 'dark'}
     style="left: {showSidebar ? '16rem' : '0'}">
  <div class="flex items-center justify-between">
    <h1 class="text-xl font-semibold"
        class:text-gray-800={currentTheme === 'light'}
        class:text-gray-100={currentTheme === 'dark'}>
      Open Email
    </h1>
    
    <div class="flex items-center space-x-4">
      <button class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
              class:hover:bg-gray-700={currentTheme === 'dark'}
              class:hover:bg-gray-100={currentTheme === 'light'}
              aria-label="Notifications">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
      </button>
      
      <div class="flex rounded-lg overflow-hidden border"
           class:border-gray-600={currentTheme === 'dark'}
           class:border-gray-300={currentTheme === 'light'}>
        <button
          on:click={() => setTheme('light')}
          class={`flex-1 py-2 px-3 flex items-center justify-center gap-1 transition-colors ${currentTheme === 'light' ? 'bg-blue-500 text-white' : 'hover:bg-opacity-20'}`}
          class:hover:bg-gray-700={currentTheme === 'dark' && currentTheme !== 'light'}
          class:hover:bg-gray-100={currentTheme === 'light' && currentTheme !== 'light'}
          aria-label="Light theme"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" />
          </svg>
        </button>
        
        <button
          on:click={() => setTheme('dark')}
          class={`flex-1 py-2 px-3 flex items-center justify-center gap-1 transition-colors ${currentTheme === 'dark' ? 'bg-blue-500 text-white' : 'hover:bg-opacity-20'}`}
          class:hover:bg-gray-700={currentTheme === 'dark' && currentTheme !== 'dark'}
          class:hover:bg-gray-100={currentTheme === 'light' && currentTheme !== 'dark'}
          aria-label="Dark theme"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
          </svg>
        </button>
      </div>
    </div>
  </div>
</nav>