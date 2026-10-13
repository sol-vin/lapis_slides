require "../codex"

module LapisSlides
  module Core
    # Pure Tier-1 value model representing a target conference.
    struct ConferenceTargetSpec
      getter name : String
      getter city : String
      getter date : String
      getter track : String
      getter url : String
      getter max_words : Int32

      def initialize(
        @name : String,
        @city : String = "",
        @date : String = "",
        @track : String = "General / Systems",
        @url : String = "",
        @max_words : Int32 = 500
      )
      end
    end

    # Pure Tier-1 value model for speaker profile and credentials.
    struct SpeakerBioSpec
      getter name : String
      getter handle : String
      getter role : String
      getter location : String
      getter cves : Array(String)
      getter certifications : Array(String)
      getter games_shipped : Array(String)
      getter jam_awards : Array(String)
      getter previous_talks : Array(String)
      getter short_bio : String
      getter standard_bio : String
      getter full_bio : String
      getter links : Hash(String, String)

      def initialize(
        @name : String = "Ian Rash",
        @handle : String = "sol.vin",
        @role : String = "Founder & Systems Architect, Sol-Vin Systems",
        @location : String = "United States",
        @cves : Array(String) = ["CVE-2019-11014", "CVE-2019-11878"],
        @certifications : Array(String) = ["CompTIA A+", "CompTIA Network+"],
        @games_shipped : Array(String) = ["Solo Oasis: Unlimited Places (Steam & itch.io)"],
        @jam_awards : Array(String) = ["Trijam 363 (1st Place, <3h)", "1dayjam #3 (1st Place, 24h)"],
        @previous_talks : Array(String) = ["Crystal 1.0 Conf (2021)", "Raw Crystal (2020)"],
        @short_bio : String = "",
        @standard_bio : String = "",
        @full_bio : String = "",
        @links : Hash(String, String) = Hash(String, String).new
      )
      end
    end

    # Pure Tier-1 value model for an outline section in the CFP.
    struct CfpOutlineSection
      getter title : String
      getter minutes : Int32
      getter bullets : Array(String)

      def initialize(@title : String, @minutes : Int32, @bullets : Array(String) = [] of String)
      end
    end

    # Pure Tier-1 value model representing a complete CFP proposal package.
    struct CfpSubmissionSpec
      getter title : String
      getter subtitle : String
      getter alternative_titles : Array(String)
      getter format : String
      getter duration_minutes : Int32
      getter audience_level : String
      getter target_audiences : Array(String)
      getter prerequisites : Array(String)
      getter elevator_pitch : String
      getter short_abstract : String
      getter detailed_abstract : String
      getter key_takeaways : Array(String)
      getter outline : Array(CfpOutlineSection)
      getter target_conferences : Array(ConferenceTargetSpec)
      getter speaker : SpeakerBioSpec
      getter technical_requirements : Array(String)
      getter tags : Array(String)

      def initialize(
        @title : String,
        @subtitle : String = "",
        @alternative_titles : Array(String) = [] of String,
        @format : String = "30-Minute Keynote / Featured Presentation",
        @duration_minutes : Int32 = 30,
        @audience_level : String = "Intermediate to Advanced",
        @target_audiences : Array(String) = [] of String,
        @prerequisites : Array(String) = [] of String,
        @elevator_pitch : String = "",
        @short_abstract : String = "",
        @detailed_abstract : String = "",
        @key_takeaways : Array(String) = [] of String,
        @outline : Array(CfpOutlineSection) = [] of CfpOutlineSection,
        @target_conferences : Array(ConferenceTargetSpec) = [] of ConferenceTargetSpec,
        @speaker : SpeakerBioSpec = SpeakerBioSpec.new,
        @technical_requirements : Array(String) = [] of String,
        @tags : Array(String) = [] of String
      )
      end

      def outline_total_minutes : Int32
        @outline.sum(&.minutes)
      end

      def abstract_word_count : Int32
        @detailed_abstract.split(/\s+/).reject(&.empty?).size
      end
    end

    # Validation errors for CFP
    struct CfpValidationError
      getter field : String
      getter message : String

      def initialize(@field : String, @message : String)
      end
    end

    # Tier-1 Invariant validator for CFP specifications
    class CfpValidator
      def self.validate(cfp : CfpSubmissionSpec) : Array(CfpValidationError)
        errors = [] of CfpValidationError

        errors << CfpValidationError.new("title", "CFP title cannot be empty") if cfp.title.strip.empty?
        errors << CfpValidationError.new("elevator_pitch", "Elevator pitch cannot be empty") if cfp.elevator_pitch.strip.empty?
        errors << CfpValidationError.new("short_abstract", "Short abstract cannot be empty") if cfp.short_abstract.strip.empty?
        errors << CfpValidationError.new("detailed_abstract", "Detailed abstract cannot be empty") if cfp.detailed_abstract.strip.empty?

        if cfp.key_takeaways.size < 3
          errors << CfpValidationError.new("key_takeaways", "Must include at least 3 concrete key takeaways")
        end

        if cfp.outline.empty?
          errors << CfpValidationError.new("outline", "Outline cannot be empty")
        elsif cfp.outline_total_minutes != cfp.duration_minutes
          errors << CfpValidationError.new("outline", "Outline minutes (#{cfp.outline_total_minutes}m) must match duration (#{cfp.duration_minutes}m)")
        end

        if cfp.target_conferences.empty?
          errors << CfpValidationError.new("target_conferences", "Must specify at least one target conference")
        end

        errors
      end
    end

    # Tier-1 Compiler for CFP specifications producing Markdown
    class CfpCompiler
      def self.emit_markdown(cfp : CfpSubmissionSpec) : String
        String.build do |io|
          io << "# Conference Call for Proposals (CFP) — " << cfp.title << "\n\n"
          io << "> **Subtitle**: " << cfp.subtitle << "  \n"
          io << "> **Speaker**: " << cfp.speaker.name << " (`" << cfp.speaker.handle << "`) | " << cfp.speaker.role << "  \n"
          io << "> **Format**: " << cfp.format << " (" << cfp.duration_minutes << " Minutes) | **Level**: " << cfp.audience_level << "\n\n"
          io << "---\n\n"

          io << "## 1. Title Variations\n\n"
          io << "- **Primary Title**: " << cfp.title << "\n"
          cfp.alternative_titles.each do |alt|
            io << "- **Alternative Title**: " << alt << "\n"
          end
          io << "\n"

          io << "## 2. Target Conferences & Tracks\n\n"
          io << "| Conference | Location | Dates | Track | Word Limit |\n"
          io << "| :--- | :--- | :--- | :--- | :--- |\n"
          cfp.target_conferences.each do |conf|
            io << "| **" << conf.name << "** | " << conf.city << " | " << conf.date << " | `" << conf.track << "` | " << conf.max_words << " words |\n"
          end
          io << "\n"

          io << "## 3. Elevator Pitch (50 Words)\n\n"
          io << cfp.elevator_pitch.strip << "\n\n"

          io << "## 4. Short Abstract (100–150 Words)\n\n"
          io << cfp.short_abstract.strip << "\n\n"

          io << "## 5. Comprehensive Abstract / Proposal\n\n"
          io << cfp.detailed_abstract.strip << "\n\n"

          io << "## 6. Key Attendee Takeaways\n\n"
          cfp.key_takeaways.each_with_index do |takeaway, idx|
            io << (idx + 1) << ". " << takeaway << "\n"
          end
          io << "\n"

          io << "## 7. Talk Outline & Timed Breakdown (" << cfp.duration_minutes << " Minutes)\n\n"
          cfp.outline.each do |sec|
            io << "### " << sec.title << " (" << sec.minutes << " min)\n"
            sec.bullets.each do |bullet|
              io << "- " << bullet << "\n"
            end
            io << "\n"
          end

          io << "## 8. Target Audience & Prerequisites\n\n"
          io << "**Target Audience**:\n"
          cfp.target_audiences.each { |a| io << "- " << a << "\n" }
          io << "\n**Prerequisites**:\n"
          cfp.prerequisites.each { |p| io << "- " << p << "\n" }
          io << "\n"

          io << "## 9. Speaker Biography & Credentials\n\n"
          io << "### " << cfp.speaker.name << " (`" << cfp.speaker.handle << "`)\n"
          io << "**Role**: " << cfp.speaker.role << "  \n"
          io << "**Location**: " << cfp.speaker.location << "\n\n"
          io << "**Bio**:\n"
          io << cfp.speaker.standard_bio.strip << "\n\n"

          io << "**Notable Credentials & Shipped Work**:\n"
          io << "- **Published Security CVEs**: " << cfp.speaker.cves.join(", ") << "\n"
          io << "- **Professional Certifications**: " << cfp.speaker.certifications.join(", ") << "\n"
          io << "- **Shipped Commercial Games**: " << cfp.speaker.games_shipped.join(", ") << "\n"
          io << "- **Game Jam Honors**: " << cfp.speaker.jam_awards.join(", ") << "\n"
          io << "- **Past Speaking Engagements**: " << cfp.speaker.previous_talks.join(", ") << "\n\n"

          unless cfp.speaker.links.empty?
            io << "**Links**:\n"
            cfp.speaker.links.each do |label, url|
              io << "- " << label << ": <" << url << ">\n"
            end
            io << "\n"
          end

          io << "## 10. Technical Requirements & Setup\n\n"
          cfp.technical_requirements.each do |req|
            io << "- " << req << "\n"
          end
          io << "\n"

          unless cfp.tags.empty?
            io << "**Tags**: `" << cfp.tags.join("`, `") << "`\n"
          end
        end
      end
    end
  end
end
