// RupertoPayQuest.ink
// Dialogue recovered from RupertoPayQuest.torch (Orchestrator/OScript visual script).
// Only the narrative content and its original author comments are kept here;
// engine wiring (advance_quest calls, close_subloc/remove_blocking, signals,
// the on-screen debug prints, etc.) has been left out except where noted inline.

=== Start ===

    @INTRO: Toshiro
    
    WOM: Room... Bzzz... Needs... Cleaning... Bzz...

    Ruperto: Piss off [i]ferraglia[/i]... this is not a place for a celebrity... Tell you master I won't pay a dime.

    WOM: Master won't be pleased sir...
    
    @SET_KNOT: LeaveMeAlone
    @TELEPORT: Morlako


-> END

=== LeaveMeAlone ===

    Ruperto: Go on [i]ferraglia[/i]... Call your master if you dare!

-> END

=== ruperto_holly_clash ===

    Ruperto: [i]Ciao bellezza[/i] looking for tendernesss?

    Holly: I like better lizards than worms... Pay your rent!

    Ruperto: Me being here should be reward enough, [i]zuccherino[/i]!

    *   [Flirt]
        Holly: You're right, you're sooooo coooool! You know, we shouldn't be buggin' you... Smack!

        // Speaker field in the source is literally "RupertoSEDUCE SOFT" — looks like a
        // leftover delivery-direction note ("seduce soft") concatenated into the name.
        Ruperto: Well, you're hot and kind, take my autographed photo, that's more than enough for staying in this [i]topaia[/i]!
-> END

    *   [Kick his ass]
        Holly: It's about time you learn some manners!

        Ruperto: [i]In guardia![/i]!
-> END

        // On-screen debug print shown during this beat: "A Battle is raging!"
        Ruperto:  Sigh! You could've messed up my look. I finally will pay for this [i]cesso[/i]! Sniff...update

        Holly: Piss off, lamer!
}


=== ruperto_morning_routine ===
{ _already_visited:
    Ruperto: C'mon. Don't waste my precious time!
- else:
    WOM: Room... Bzzz... Needs... Cleaning... Bzz...

    Ruperto: It's good your master appreciates a real artist, go on [i]ferraglia[/i]

    WOM: Me... Quick...

    ~ _already_visited = true
    // Note: this function never calls advance_quest in the source script, so
    // `advancement` stays at 2 (Flirted) until ruperto_leaving is triggered
    // some other way.
}
-> DONE

=== ruperto_leaving ===
Ruperto: I'm leaving this place for good!
-> END
