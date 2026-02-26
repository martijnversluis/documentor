# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Review Templates
if ReviewTemplate.count == 0
  puts "Creating review templates..."

  # Daily Start
  daily_start = ReviewTemplate.create!(
    review_type: "daily_start",
    name: "Dag start",
    active: true
  )

  daily_start.review_template_steps.create!([
    {
      title: "Bureau opgeruimd?",
      position: 0
    },
    {
      title: "Dag einde van gisteren afgerond?",
      position: 1
    },
    {
      title: "Hoofd leeg?",
      position: 2
    }
  ])

  # Daily End
  daily_end = ReviewTemplate.create!(
    review_type: "daily_end",
    name: "Dag einde",
    active: true
  )

  daily_end.review_template_steps.create!([
    {
      title: "Lijst afgewerkt?",
      position: 0,
      description: "Zijn [taken](//action_items/today) afgewerkt of verplaatst naar morgen? Wat moet er vanavond nog worden gedaan?"
    },
    {
      title: "Hoofd leeg?",
      position: 1
    },
    {
      title: "Agenda voor morgen bekeken?",
      position: 2,
      description: "Bekijk de [agenda voor morgen](//action_items/tomorrow)"
    }
  ])

  # Weekly Review
  weekly = ReviewTemplate.create!(
    review_type: "weekly",
    name: "Wekelijkse Review",
    description: "GTD wekelijkse review om je systeem up-to-date te houden",
    active: true
  )

  weekly.review_template_steps.create!([
    {
      title: "Verzamel losse papieren en materialen",
      position: 0,
      description: <<~MD

        - Bureau opruimen
        - Notities uit zakken/tas
        - Bonnetjes en visitekaartjes
        - Downloads folder checken
        Verzamel alles wat rondslingert en verwerk het naar je [inbox](//inbox).
      MD
    },
    {
      title: "Verwerk je inbox",
      position: 1,
      description: <<~MD
        Verwerk alle items in je [inbox](//inbox) tot deze leeg is.

        Voor elk item: Is het actionable?
        - **Nee**: Weg, archief, of someday/maybe
        - **Ja**: Doe het (<2 min), delegeer, of plan het
      MD
    },
    {
      title: "Leeg je hoofd",
      position: 2,
      description: <<~MD
        Schrijf alles op wat nog in je hoofd zit.

        - Nieuwe projecten?
        - Taken die je bent vergeten?
        - Afspraken die je moet maken?
        - Dingen die je dwars zitten?
      MD
    },
    {
      title: "Bekijk verlopen actiepunten",
      position: 3,
      description: <<~MD
        Review alle [verlopen items](//action_items/overdue).

        - Herplan of verwijder ze
        - Vraag je af: is dit nog relevant?
      MD
    },
    {
      title: "Bekijk eerstvolgende acties. ",
      position: 4,
      description: <<~MD
        Bekijk de [eerstvolgende acties](//action_items/next_actions).

        Voor elk item: Is het actionable?
        - **Nee**: Weg, archief, of someday/maybe
        - **Ja**: Doe het (<2 min), delegeer, of plan het
      MD
    },
    {
      title: "Controleer wacht-op items",
      position: 5,
      description: <<~MD
        Loop door je [wacht-op lijst](//action_items/waiting).

        - Moet je ergens achteraan?
        - Zijn er items die je kunt afronden?
        - Heb je een reminder nodig?
      MD
    },
    {
      title: "Review je projecten",
      position: 6,
      description: <<~MD
        Heeft elk actief [project](//dossiers) een duidelijke volgende actie?

        - Zijn er projecten die je moet toevoegen?
        - Zijn er projecten die je kunt afsluiten?
        - Welke projecten hebben prioriteit?
      MD
    },
    {
      title: "Bekijk someday/maybe",
      position: 7,
      description: <<~MD
        Scan je [someday/maybe lijst](//action_items/someday).

        - Is er iets dat je nu wilt oppakken?
        - Zijn er items die niet meer relevant zijn?
      MD
    },
    {
      title: "Plan de komende week",
      position: 8,
      description: <<~MD
        Kijk vooruit naar de [komende week](//action_items/week/next).

        - Welke afspraken heb je?
        - Welke deadlines komen eraan?
        - Wat wil je zeker bereiken?
      MD
    }
  ])

  # Monthly Review
  monthly = ReviewTemplate.create!(
    review_type: "monthly",
    name: "Maandelijkse Review",
    description: "Diepere review van je systeem en doelen",
    active: true
  )

  monthly.review_template_steps.create!([
    {
      title: "Projecten-review",
      position: 0,
      description: <<~MD
        [Bekijk projecten](//dossiers)

        - Welke projecten zijn afgerond?
        - Welke lopen vast of slepen?
        - Moeten projecten worden stopgezet, vereenvoudigd of opgesplitst?
      MD
    },
    {
      title: "Backlog & Someday/Maybe",
      position: 1,
      description: <<~MD
        [Bekijk someday/maybe](//action_items/someday)

        - Is er iets dat nu actief moet worden?
        - Staat er iets op mijn lijst dat eigenlijk niet meer relevant is?
      MD
    },
    {
      title: "Rollen & verantwoordelijkheden",
      position: 2,
      description: <<~MD
        Werk / persoon / man / vader / gezondheid / relaties / creatief / leren

        Krijgt elke belangrijke rol genoeg aandacht?
      MD
    },
    {
      title: "Capaciteit-check",
      position: 3,
      description: <<~MD
        - Heb ik structureel te veel / te weinig op mijn bord?
        - Waar zeg ik te vaak "ja" tegen?
      MD
    },
    {
      title: "Vooruitkijken (1-2 maanden)",
      position: 4,
      description: <<~MD
        [Bekijk volgende maand](//action_items/month/next)

        - Grote deadlines of gebeurtenissen komende 1–2 maanden
        - Wat vraagt nu alvast aandacht?
      MD
    }
  ])

  # Quarterly Review
  quarterly = ReviewTemplate.create!(
    review_type: "quarterly",
    name: "Kwartaalreview",
    description: "Strategische review van je grotere doelen",
    active: true
  )

  quarterly.review_template_steps.create!([
    {
      title: "Doelen & outcomes",
      position: 0,
      description: <<~MD
        - Wat wilde ik dit kwartaal bereiken?
        - Wat is écht gelukt (niet alleen afgerond, maar met effect)?
      MD
    },
    {
      title: "Patronen herkennen",
      position: 1,
      description: <<~MD
        - Waar ging mijn tijd naartoe?
        - Wat gaf energie / wat trok energie weg?
      MD
    },
    {
      title: "Prioriteiten herijken",
      position: 2,
      description: <<~MD
        - Welke 3–5 thema's zijn nu het belangrijkst?
        - Wat moet dit kwartaal expliciet lager prioriteit krijgen?
      MD
    },
    {
      title: "Systemen & werkwijze",
      position: 3,
      description: <<~MD
        - Werkt mijn GTD-systeem nog?
        - Waar zit frictie (te veel lijsten, te weinig overzicht, etc.)?
      MD
    },
    {
      title: "Risico's & kansen",
      position: 4,
      description: <<~MD
        - Wat zie ik aankomen dat aandacht vraagt?
        - Waar kan ik met weinig moeite veel impact maken?
      MD
    }
  ])

  # Yearly Review
  yearly = ReviewTemplate.create!(
    review_type: "yearly",
    name: "Jaarlijkse Review",
    description: "Reflectie op het afgelopen jaar en planning voor het nieuwe jaar",
    active: true
  )

  yearly.review_template_steps.create!([
    {
      title: "Terugblik",
      position: 0,
      description: <<~MD
        - Wat waren de hoogte- en dieptepunten?
        - Waar ben ik trots op?
        - Wat heb ik geleerd?
      MD
    },
    {
      title: "Waarden & identiteit",
      position: 1,
      description: <<~MD
        - Wat vond ik dit jaar echt belangrijk?
        - Waar leefde ik in lijn met mijn waarden – en waar niet?
      MD
    },
    {
      title: "Levensgebieden",
      position: 2,
      description: <<~MD
        Werk, relaties, gezondheid, financiën, creativiteit, persoonlijke groei

        Wat staat er goed voor? Wat vraagt aandacht?
      MD
    },
    {
      title: "Langetermijnrichting",
      position: 3,
      description: <<~MD
        - Waar wil ik over 3–5 jaar staan?
        - Wat betekent dat concreet voor komend jaar?
      MD
    },
    {
      title: "Intenties voor het nieuwe jaar",
      position: 4,
      description: <<~MD
        Geen takenlijst, maar:
        - Thema's
        - Focuswoorden
        - Dingen die ik bewuster niet meer ga doen
      MD
    }
  ])

  puts "Review templates created!"
end
