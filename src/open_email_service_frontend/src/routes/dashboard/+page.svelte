<script>
    import { signOut } from "$lib/services/auth.service";
    import { authSignedInStore } from "$lib/derived/auth.derived";
    import InboxComponent from '../../lib/components/inbox.svelte'

    if(!authSignedInStore){
        signOut();
    }
    </script>
    
    <main>
        <InboxComponent />
    </main>