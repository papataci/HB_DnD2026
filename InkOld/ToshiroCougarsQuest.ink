// ToshiroCougarsQuest.ink
// Dialogue recovered from ToshiroCougarsQuest.torch (Orchestrator/OScript visual script).
// Only the narrative content and its original author comments are kept here;
// engine wiring (advance_quest calls, close_subloc/remove_blocking, signals,
// the on-screen debug prints, etc.) has been left out.

// Advancement (comment node "Advancement" attached to the quest_play switch):
// 0: first contact
// 1: WOM bounced
// 2: Flirted
// 3: Beaten   <- no dialogue exists for this stage yet in the source file

VAR advancement = 0
VAR _already_visited = false
VAR _queued_advancement = 0

-> toshiro_first_contact

=== toshiro_first_contact ===
{ _already_visited:
    -> toshiro_gets_mad ->
- else:
    WOM: Room... Bzzz... Needs... Cleaning... Bzz...

    Toshiro: いいよ、それから出て行って, I'm meditating...
    // (Ii yo, sore kara dete itte). Questa frase combina "va bene" (いいよ) con "poi smamma" (それから出て行って)

    WOM: ありがとうございます Sir... Me quick.

    ~ advancement = 1
    ~ _already_visited = true
}
-> DONE

=== toshiro_meets_holly ===
{ _already_visited:
    -> toshiro_gets_mad ->
- else:
    Holly: Good morning sir. How's your stay?

    Toshiro: (なんて美人だ) Hello to you... As you may have guessed privacy and silence are top priority for me.
    // L'espressione italiana "che gnocca" può essere tradotta in giapponese in modo approssimativo come "なんて美人だ" (nante bijin da). Questa traduzione si avvicina al significato di "che bella ragazza" o "che donna attraente".
    // Dettagli della Traduzione:
    //
    //     なんて (nante): Esprime sorpresa o ammirazione, simile a "che" in italiano.
    //     美人 (bijin): Significa "bella donna" o "bellezza".
    //     だ (da): È una particella finale che afferma o enfatizza la frase.
    //
    // Questa traduzione mantiene un tono rispettoso e meno volgare rispetto all'originale italiano. Se desideri un tono più colloquiale o familiare, puoi usare anche "すごい美人だ" (sugoi bijin da), dove "すごい" (sugoi) significa "incredibile" o "molto".

    Holly: This place can be messy at times, we'll see what i can do.

    Toshiro: (ラムちゃんのコスチュームを着た君が見たい。) Have a nice day.
    // Per dire "Vorrei vederti in costume da Lamù" in giapponese, puoi dire:
    // ラムちゃんのコスチュームを着た君が見たい。
    // (Ramu-chan no kosuchūmu o kita kimi ga mitai.)

    Holly: (Dream on, fucker.)

    ~ advancement = 2
    ~ _already_visited = true
}
-> DONE

=== toshiro_gets_mad ===
// Japanise considerations (comment node attached to this function in the source file —
// it duplicates the いいよ note from toshiro_first_contact and adds the うるさい奴 note below):
//
// Toshiro: いいよ、それから出て行って, I'm meditating...
// (Ii yo, sore kara dete itte). Questa frase combina "va bene" (いいよ) con "poi smamma" (それから出て行って)
//
// Toshiro: うるさい奴!
// Un altro termine colloquiale è "うるさいやつ" (urusai yatsu), che si traduce in "persona rumorosa" o "persona irritante".
// "うるさい奴ら" (urusai yatsura) significa "persone rumorose" o "persone fastidiose".
// Il termine "yatsura" è un modo colloquiale e un po' dispregiativo per dire "gente" o "persone".
// Quindi, "urusai yatsura" si riferisce a un gruppo di persone che sono fastidiose o rumorose.

Toshiro: うるさい奴!
->->
