# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Review Templates
if ReviewTemplate.count == 0
  puts "Creating review templates..."

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
        Verzamel alles wat rondslingert en verwerk het naar je inbox.

        - Bureau opruimen
        - Notities uit zakken/tas
        - Bonnetjes en visitekaartjes
        - Downloads folder checken
      MD
    },
    {
      title: "Verwerk je inbox",
      position: 1,
      description: <<~MD
        Verwerk alle items in je inbox tot deze leeg is.

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
        Review alle items die over de deadline zijn.

        - Herplan of verwijder ze
        - Vraag je af: is dit nog relevant?
      MD
    },
    {
      title: "Controleer wacht-op items",
      position: 4,
      description: <<~MD
        Loop door je wacht-op lijst.

        - Moet je ergens achteraan?
        - Zijn er items die je kunt afronden?
        - Heb je een reminder nodig?
      MD
    },
    {
      title: "Review je projecten",
      position: 5,
      description: <<~MD
        Heeft elk actief project een duidelijke volgende actie?

        - Zijn er projecten die je moet toevoegen?
        - Zijn er projecten die je kunt afsluiten?
        - Welke projecten hebben prioriteit?
      MD
    },
    {
      title: "Bekijk someday/maybe",
      position: 6,
      description: <<~MD
        Scan je someday/maybe lijst.

        - Is er iets dat je nu wilt oppakken?
        - Zijn er items die niet meer relevant zijn?
      MD
    },
    {
      title: "Plan de komende week",
      position: 7,
      description: <<~MD
        Kijk vooruit naar de komende week.

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
      title: "Voltooi wekelijkse review",
      position: 0,
      description: "Zorg dat je wekelijkse review volledig is afgerond voordat je doorgaat."
    },
    {
      title: "Review maanddoelen",
      position: 1,
      description: <<~MD
        Kijk terug naar afgelopen maand.

        - Heb je je doelen behaald?
        - Wat ging goed?
        - Wat kan beter?
      MD
    },
    {
      title: "Stel doelen voor volgende maand",
      position: 2,
      description: <<~MD
        Wat wil je volgende maand bereiken?

        Maak het specifiek en meetbaar.
      MD
    },
    {
      title: "Review lopende projecten",
      position: 3,
      description: <<~MD
        Zijn er projecten die vastlopen?

        - Heb je hulp nodig?
        - Moet je iets delegeren?
        - Zijn er blokkades?
      MD
    },
    {
      title: "Opschonen someday/maybe",
      position: 4,
      description: <<~MD
        Verwijder items die niet meer relevant zijn.

        Promoveer items naar actieve projecten als de tijd rijp is.
      MD
    },
    {
      title: "Review je systeem",
      position: 5,
      description: <<~MD
        Werkt je huidige systeem?

        - Mis je bepaalde lijsten of contexten?
        - Zijn er verbeteringen mogelijk?
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
      title: "Voltooi maandelijkse review",
      position: 0,
      description: "Zorg dat je maandelijkse review volledig is afgerond."
    },
    {
      title: "Review kwartaaldoelen",
      position: 1,
      description: <<~MD
        Evalueer het afgelopen kwartaal.

        - Welke grote mijlpalen heb je bereikt?
        - Wat heeft je tegengehouden?
      MD
    },
    {
      title: "Review jaardoelen voortgang",
      position: 2,
      description: <<~MD
        Hoe sta je ervoor met je jaardoelen?

        - Ben je op schema?
        - Moeten doelen worden aangepast?
      MD
    },
    {
      title: "Stel kwartaaldoelen",
      position: 3,
      description: <<~MD
        Wat wil je komend kwartaal bereiken?

        Focus op 2-3 grote prioriteiten.
      MD
    },
    {
      title: "Review grote projecten",
      position: 4,
      description: <<~MD
        Bekijk je belangrijkste projecten.

        - Zijn ze nog in lijn met je doelen?
        - Moeten prioriteiten verschuiven?
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
      title: "Reflecteer op het afgelopen jaar",
      position: 0,
      description: <<~MD
        Kijk terug op het afgelopen jaar.

        - Wat waren je grootste successen?
        - Wat waren de moeilijkste momenten?
        - Wat heb je geleerd?
      MD
    },
    {
      title: "Review jaardoelen",
      position: 1,
      description: <<~MD
        Evalueer je jaardoelen.

        - Welke doelen heb je behaald?
        - Welke niet, en waarom?
      MD
    },
    {
      title: "Dankbaarheid",
      position: 2,
      description: <<~MD
        Waar ben je dankbaar voor dit jaar?

        - Mensen die je hebben geholpen
        - Kansen die je hebt gekregen
        - Lessen die je hebt geleerd
      MD
    },
    {
      title: "Loslaten",
      position: 3,
      description: <<~MD
        Wat wil je loslaten?

        - Oude projecten die niet meer relevant zijn
        - Gewoontes die je niet meer dienen
        - Zorgen die je niet kunt controleren
      MD
    },
    {
      title: "Visie voor het nieuwe jaar",
      position: 4,
      description: <<~MD
        Hoe wil je dat het nieuwe jaar eruitziet?

        - Werk en carriere
        - Persoonlijke ontwikkeling
        - Relaties en gezondheid
      MD
    },
    {
      title: "Stel jaardoelen",
      position: 5,
      description: <<~MD
        Kies 3-5 belangrijke doelen voor het nieuwe jaar.

        Maak ze specifiek, meetbaar en realistisch.
      MD
    },
    {
      title: "Eerste stappen",
      position: 6,
      description: <<~MD
        Wat zijn de eerste concrete stappen?

        Plan de eerste acties voor je belangrijkste doelen.
      MD
    }
  ])

  puts "Review templates created!"
end
