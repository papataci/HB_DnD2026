=== Start ===
    @INTRO: Ruperto

    WOM: Room... Bzzz... Needs... Cleaning... Bzz...

    Ruperto: Piss off [i]ferraglia[/i]... this is not a place for a celebrity... Tell you master I won't pay a dime.

    WOM: Master won't be pleased sir...
    
    @SET_KNOT: LeaveMeAlone
    @CLOSE: room08
    @RESOLVE_ROOM:
    @CLOSE:
    @TELEPORT: Morlako


-> END


=== RoomRefused ===
@MCP: Bzzz... Tenant... is... An asshole, bzzz... Boss intervention is requested.
@TELEPORT: Morlako

-> END




=== LeaveMeAlone ===

    Ruperto: Go on [i]ferraglia[/i]... Call your master if you dare!

-> END

// RupertoPayQuest.ink
// Dialogue recovered from RupertoPayQuest.torch (Orchestrator/OScript visual script).
// Only the narrative content and its original author comments are kept here;
// engine wiring (advance_quest calls, close_subloc/remove_blocking, signals,
// the on-screen debug prints, etc.) has been left out except where noted inline.

// Advancement (comment node "Advancement" attached to the quest_play switch):
// 0: first contact
// 1: WOM bounced
// 2: Flirted
// 3: Beaten
//
// The quest_play switch on `advancement` actually dispatches to four different
// functions (0 -> ruperto_first_contact, 1 -> ruperto_holly_clash,
// 2 -> ruperto_morning_routine, 3 -> ruperto_leaving); the "Flirted"/"Beaten"
// labels above map to the two dialogue choices inside ruperto_holly_clash,
// which is itself the "WOM bounced" stage's follow-up.

=== ruperto_first_contact ===
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

        // On-screen debug print shown during this beat: "A Battle is raging!"
        Ruperto:  Sigh! You could've messed up my look. I finally will pay for this [i]cesso[/i]! Sniff...update

        Holly: Piss off, lamer!
-> END

=== ruperto_morning_routine ===
    Ruperto: C'mon. Don't waste my precious time!



    WOM: Room... Bzzz... Needs... Cleaning... Bzz...

    Ruperto: It's good your master appreciates a real artist, go on [i]ferraglia[/i]

    WOM: Me... Quick...

-> END



=== ruperto_leaving ===
Ruperto: I'm leaving this place for good!
-> END
