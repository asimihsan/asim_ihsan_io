---
title: "Healthy breathing with a smart bulb"
date: 2020-08-13T20:00:00-07:00
aliases:
  - /posts/healthy-breathing-with-a-smart-bulb/
  - /healthy-breathing-with-a-smart-bulb/
draft: false
summary: |
    Inhale 5 seconds, exhale 5 seconds. Research repeatedly demonstrates that this breathing pattern reduces
    anxiety, stress, high blood pressure, and insomnia, both during sessions and durably for months afterwards. In
    this article I summarize research into breathing, and also create an open-source tool that uses a smart bulb
    as a peripheral-vision breathing guide.
objectives: |
    By the end of this article you will be able to:

    -   Understand how breathing one inhale-then-exhale cycle every 10 seconds (6 breaths per minute) has positive
        health benefits.
    -   Apply different ratios of inhalation to exhalation to alter your self-perceived mood.
    -   Use a Raspberry Pi and a LIFX smart bulb as a peripheral vision breathing aid.

summary_image_enabled: true
summary_image: breathing01.svg
summary_image_title: Diagram illustrating breathing at a certain rate with the help of a smart bulb.
tags:
-   breathing
-   health
-   habits
-   relaxation
-   focus
-   smart bulb
-   LIFX
---

## Introduction

Pause. Inhale as deeply as you can. Then exhale slowly and fully. Something as simple as a deep breath can
reset a bad mood or offer a fresh perspective on a problem. Merely being present and breathing deeply is beneficial.
Yet research 

{{< newsletter_signup >}}

## Prior art

Foobat

---

## References, research papers, and articles

[^1]: Diest, Ilse Van et al. ["Inhalation/Exhalation Ratio Modulates the Effect of Slow Breathing on Heart
    Rate Variability and Relaxation."](https://lirias.kuleuven.be/retrieve/285986) Applied Psychophysiology
    and Biofeedback 39 (2014): 171-180.

    -   Preamble
        -   RSA: respiratory sinus arrythmia
        -   HRV: heart rate variability
        -   HF: high frequency
        -   "**Higher HF power or RSA would correlate with a better capacity to adapt to the environment and
            induces a calm, but alert state** (Brown & Gerbarg, 2005a). **Heart rate variability is also a
            marker of cardiovascular health and autonomic homeostatic control** (Lehrer, Sasaki, & Saito,
            1999; Thayer & Brosschot, 2005).
        -   "**According to yoga, the ideal breath rate is situated around six breaths per minute, with an
            exhalation that is twice as long as the inhalation (ratio 1:2)**. General yogic breathing is
            believed to stimulate a good mental health, as well as a state of calm alertness, mental focus and
            stress tolerance, by means of several mechanisms."
        -   "**Breathing techniques are also applied to treat cardiovascular complaints** (Grossman, Grossman,
            Schein, Zimlichman, & Gavish, 2001; Pitzalis et al., 1998).  E.g., a FDA-approved intervention in
            reducing high blood pressure in hypertensives involves device-guided breathing exercises (see
            https://www.resperate.com).  With differentiated inspiration and expiration “sounds” the user is
            guided to lower the respiratory frequency to less than 10 breaths/minwith prolonged expiration.
            Studies on the efficacy of this treatment (Grossman et al., 2001; Logtenberg, Kleefstra,
            Houweling, Groenier, & Bilo, 2007; Rosenthal, Alter, Peleg, & Gavish, 2001; Schein et al., 2009;
            Viskoper et al., 2003) reported significant reductions in systolic blood pressure."
    -   Experiment
        -   First breathing video: inhalation 1.5s, exhalation 3.5s, 12 breaths/min (low ratio)
        -   Second breathing video: inhalation 3.5s, exhalation 1.5s, 12 breaths/min (high ratio)
        -   Third breathing video: inhalation 3s, exhalation 7s, 6 breaths/min (low ratio)
        -   Fourth breathing video: inhalation 7s, exhalation 3s, 6 breaths/min (high ratio)
    -   Results
        -   "Generally, our findings show that **i/e ratio is the more important determinant for self-reported
            effects of relaxation as obtained by instructed breathing**.  Although participants did not expect
            such effect prior to performing the breathing exercises, they reported **higher pleasantness and
            more feelings of control for the breathing patterns with a low compared to a high i/e ratio**. In
            addition, participants reported **more relaxation, more positive energy, less stress, and higher
            mindfulness** when adopting a breathing pattern with a low i/e ratio as compared to a high i/e
            ratio.  In contrast, **effects of respiration rate were observed only for positive energy**."
        -   "A low compared to a high i/e ratio resulted in a significantly higher HF-HRV when participants
            were breathing at 6, but not at 12 breaths/minute."
        -   "In summary, the present results strongly suggest that **voluntary changes in i/e ratio are an
            important determinant of self-reported states of relaxation, and of RSA and power in the HF-band
            when breathing at 6 breaths/min**.  Our results suggest that beneficial effects of slow breathing
            described in the literature may be primarily due to concomitant changes in i/e ratio."

[^2]: André, C. ["Proper breathing brings better health. Stress reduction, insomnia prevention, emotion
    control, improved attention certain breathing techniques can make life better. But where do you
    start."](https://www.scientificamerican.com/article/proper-breathing-brings-better-health/) Scientific
    American. January 15 (2019).

    -   "Overall, **research shows that these techniques reduce anxiety, although the anxiety does not disappear
        completely. Breathing better is a tool, not a panacea**. Some methods have been validated by clinical
        studies; others have not. But all of those I describe in this article apply principles that have been
        proved effective. They aim to **slow, deepen or facilitate breathing, and they use breathing as a focal
        point or a metronome to distract attention from negative thoughts**."
    -   "A typical cardiac coherence exercise involves inhaling for five seconds, then exhaling for the same
        amount of time (for a 10-second respiratory cycle). **Biofeedback devices** make it possible to observe on
        a screen how this deep, regular breathing slows and stabilizes the beats... **Simply applying slow
        breathing with the same conviction and rigor could well give the same result**."
    -   "Some versions of cardiac coherence recommend **spending more time on exhaling than on inhaling (for
        example, six and four seconds)**. Indeed, your heart rate increases slightly when you inhale and decreases
        when you exhale: **drawing out the second phase probably exerts a quieting effect on the heart and, by
        extension, on the brain**. This possibility remains to be confirmed by clinical studies, however."
    -   "What is the best time to apply slow-breathing techniques?"
        -   "One is during occasional episodes of stress—for example, before taking an exam, competing in a
            sporting event or even attending a routine meeting at work."
        -   "These exercises may also help when insomnia strikes."
        -   "But respiratory techniques do not work only for acute stresses or sleep problems; they can also
            relieve chronic anxiety...Even better, **improvement was maintained two and six months later, with
            follow-up sessions just once a week and some home practice during this period**.
        -   "Breathing exercises also help to counter the accumulation of minor physical tension associated with
            stress. **Therapists recommend doing them regularly during the day**, during breaks or at moments of
            transition between two activities: you simply stop to adjust your posture and allow yourself a few
            minutes of quiet breathing. Therapists often suggest the **"365 method": at least three times a day,
            breathe at a rhythm of six cycles per minute (five seconds inhaling, five seconds exhaling) for five
            minutes. And do it every day, 365 days a year**. Some studies even suggest that, in addition to
            providing immediate relief, regular breathing exercises can make people less vulnerable to stress, by
            permanently modifying brain circuits."

[^3]: David Robston, ["Why slowing your breathing helps you
    relax"](https://www.bbc.com/worklife/article/20200303-why-slowing-your-breathing-helps-you-relax), BBC,
    March 2 (2020)

    -   "**A recent review of the relevant scientific literature found that slow, deep breathing can help
        alleviate the symptoms of depression and anxiety, and it also appears to help relieve insomnia.**"
    -   "Interestingly, **people practicing breathwork seem to find a sweet spot at around six breaths a minute**.
        This appears to bring about markedly greater relaxation through some kind of a positive feedback loop
        between the lungs, the heart and the brain. “You’re kind of unlocking or promoting the amplification of a
        basic physiological rhythm,” says Noble. He points out that this frequency can be found in the repetitive
        actions of many spiritual practices – such as the Ave Marias spoken in rosary prayers and the chanting of
        yogic mantras. Perhaps those practices evolved through an unconscious recognition of this restorative
        breathing rhythm and its capacity to send people into a relaxed but focused state of mind."
    -   "**Besides improving cardiovascular health, the slower breathing rate of six breaths per minute also seems
        to be optimal for pain management**, according to the study by Jafari."

[^4]: Soni, Sunaina et al. ["Effect of controlled deep breathing on psychomotor and higher mental functions in
    normal
    individuals."](https://www.researchgate.net/profile/Sunaina_Soni/publication/281717219_Effect_of_controlled_deep_breathing_on_psychomotor_and_higher_mental_functions_in_normal_individuals/links/58d4f34aa6fdcc1bae4ea1d1/Effect-of-controlled-deep-breathing-on-psychomotor-and-higher-mental-functions-in-normal-individuals.pdf)
    Indian journal of physiology and pharmacology 59 1 (2015): 41-7.

    -   "100 normal healthy subjects (52 females and 48 males, age range - 18 to 25 years) participated in the
        study. Each subject acted as his or her own control. Six weeks course of controlled deep breathing i.e.
        **5 seconds of maximal inhalation followed by 5 seconds of maximal exhalation, once a day for ten minutes,
        six days a week** was arranged."
    -   "(i) Letter cancellation test (ii) Rapid fire arithmetic deviation testand (iii) Playing card test were
        conducted before and after six weeks of controlled deep breathing practicefor evaluating psychomotor and
        higher mental functions"
    -   "**The results suggest that a short, simple breathing practice can be helpful in improving cognitive
        processes.**"