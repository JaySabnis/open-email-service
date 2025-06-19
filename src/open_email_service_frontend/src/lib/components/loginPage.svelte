<script>
    import { signIn } from "$lib/services/auth.services"; 
    import { goto } from "$app/navigation"; 
    import { browser } from "$app/environment"; 
    import { profileStore } from "$lib/store/profile-store";
  
    async function handleLogin() {
      // console.log("Logging in...");
      let params = {
        domain: `http://localhost:4943/?canisterId=qhbym-qaaaa-aaaaa-aaafq-cai`,
      };
      await signIn(params);
      let profile;
       profileStore.getProfile().then(async (res) => {
                profile = res.ok || null;
                console.log("Profile fetched:", profile);
            }).catch(err => {
                console.error("Background profile fetch failed:", err);
            });

      if (profile) {
        await goto(`/`);
      }

      await goto(`/profile`); 
    }
  </script>
  
  <main class="min-h-screen relative flex items-center justify-center bg-gray-100">
  
    <div class="hidden lg:block absolute inset-0">
      <!-- <img src="https://miro.medium.com/v2/resize:fit:1400/1*guz0NRDfCNOU5nnfsiEsFw.jpeg" alt="Login Image" class="w-full h-full" /> -->
    </div>
  
    <div class="relative z-10 w-full lg:w-1/3 bg-white p-6 rounded-lg shadow-lg text-center">
      <h2 class="text-2xl font-semibold mb-6">Welcome to Our Platform</h2>
      <p class="text-gray-600 mb-6">Please login to continue</p>
      <button
        on:click={handleLogin}
        class="w-full bg-blue-500 text-white py-3 px-6 rounded-lg hover:bg-blue-600 transition duration-200"
      >
        Login with Internet Identity
      </button>
    </div>
  
  </main>
  
  <style>
  </style>
  