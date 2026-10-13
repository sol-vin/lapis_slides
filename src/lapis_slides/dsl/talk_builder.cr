require "../core/cfp"
require "../core/keynote"

module LapisSlides
  module DSL
    # Tier-2 Declarative Builder for CFP Submissions
    class CfpBuilder
      def initialize(@title : String)
        @subtitle = ""
        @alternative_titles = [] of String
        @format = "30-Minute Keynote / Featured Presentation"
        @duration_minutes = 30
        @audience_level = "Intermediate to Advanced"
        @target_audiences = [] of String
        @prerequisites = [] of String
        @elevator_pitch = ""
        @short_abstract = ""
        @detailed_abstract = ""
        @key_takeaways = [] of String
        @outline = [] of Core::CfpOutlineSection
        @target_conferences = [] of Core::ConferenceTargetSpec
        @speaker = Core::SpeakerBioSpec.new
        @technical_requirements = [] of String
        @tags = [] of String
      end

      def subtitle(sub : String)
        @subtitle = sub
        self
      end

      def alt_title(alt : String)
        @alternative_titles << alt
        self
      end

      def format(fmt : String, minutes : Int32 = 30)
        @format = fmt
        @duration_minutes = minutes
        self
      end

      def audience(level : String, audiences : Array(String) = [] of String)
        @audience_level = level
        @target_audiences.concat(audiences)
        self
      end

      def prerequisite(req : String)
        @prerequisites << req
        self
      end

      def elevator_pitch(pitch : String)
        @elevator_pitch = pitch
        self
      end

      def short_abstract(abs : String)
        @short_abstract = abs
        self
      end

      def detailed_abstract(abs : String)
        @detailed_abstract = abs
        self
      end

      def takeaway(point : String)
        @key_takeaways << point
        self
      end

      def section(title : String, minutes : Int32, bullets : Array(String) = [] of String)
        @outline << Core::CfpOutlineSection.new(title, minutes, bullets)
        self
      end

      def target_conference(name : String, city : String = "", date : String = "", track : String = "General / Systems", url : String = "", max_words : Int32 = 500)
        @target_conferences << Core::ConferenceTargetSpec.new(name, city, date, track, url, max_words)
        self
      end

      def speaker(
        name : String = "Ian Rash",
        handle : String = "sol.vin",
        role : String = "Founder & Systems Architect, Sol-Vin Systems",
        location : String = "United States",
        cves : Array(String) = ["CVE-2019-11014", "CVE-2019-11878"],
        certifications : Array(String) = ["CompTIA A+", "CompTIA Network+"],
        games_shipped : Array(String) = ["Solo Oasis: Unlimited Places (Steam & itch.io)"],
        jam_awards : Array(String) = ["Trijam 363 (1st Place)", "1dayjam #3 (1st Place)"],
        previous_talks : Array(String) = ["Crystal 1.0 Conf (2021)", "Raw Crystal (2020)"],
        short_bio : String = "",
        standard_bio : String = "",
        full_bio : String = "",
        links : Hash(String, String) = Hash(String, String).new
      )
        @speaker = Core::SpeakerBioSpec.new(
          name, handle, role, location, cves, certifications, games_shipped, jam_awards, previous_talks,
          short_bio, standard_bio, full_bio, links
        )
        self
      end

      def technical_requirement(req : String)
        @technical_requirements << req
        self
      end

      def tag(t : String)
        @tags << t
        self
      end

      def build : Core::CfpSubmissionSpec
        Core::CfpSubmissionSpec.new(
          @title,
          @subtitle,
          @alternative_titles,
          @format,
          @duration_minutes,
          @audience_level,
          @target_audiences,
          @prerequisites,
          @elevator_pitch,
          @short_abstract,
          @detailed_abstract,
          @key_takeaways,
          @outline,
          @target_conferences,
          @speaker,
          @technical_requirements,
          @tags
        )
      end
    end

    # Tier-2 Declarative Builder for Beat specifications
    class BeatBuilder
      def initialize(@id : String, @title : String, @start_second : Int32, @end_second : Int32)
        @slide_ids = [] of String
        @hook = ""
        @spoken_script = ""
        @stage_cues = [] of Core::StageCue
        @visual_callouts = [] of String
        @key_insight = ""
        @tone_direction = "Confident, technical, conversational"
      end

      def slide(*ids : String)
        @slide_ids.concat(ids.to_a)
        self
      end

      def hook(text : String)
        @hook = text
        self
      end

      def say(text : String)
        @spoken_script = text
        self
      end

      def cue(type : Core::StageCueType, target : String, at : Int32, instruction : String = "")
        @stage_cues << Core::StageCue.new(type, at, target, instruction)
        self
      end

      def visual_callout(text : String)
        @visual_callouts << text
        self
      end

      def insight(text : String)
        @key_insight = text
        self
      end

      def tone(text : String)
        @tone_direction = text
        self
      end

      def build : Core::KeynoteBeatSpec
        Core::KeynoteBeatSpec.new(
          @id,
          @title,
          @start_second,
          @end_second,
          @slide_ids,
          @hook,
          @spoken_script,
          @stage_cues,
          @visual_callouts,
          @key_insight,
          @tone_direction
        )
      end
    end

    # Tier-2 Declarative Builder for Chapters (Acts)
    class ChapterBuilder
      def initialize(@act_number : Int32, @title : String, @start_second : Int32, @end_second : Int32, @purpose : String = "")
        @beats = [] of Core::KeynoteBeatSpec
      end

      def beat(id : String, title : String, from start_s : Int32, to end_s : Int32, &block : BeatBuilder ->)
        builder = BeatBuilder.new(id, title, start_s, end_s)
        yield builder
        @beats << builder.build
        self
      end

      def build : Core::KeynoteChapterSpec
        Core::KeynoteChapterSpec.new(
          @act_number,
          "Act #{@act_number}",
          @title,
          @start_second,
          @end_second,
          @purpose,
          @beats
        )
      end
    end

    # Tier-2 Declarative Builder for Keynote Choreography
    class KeynoteBuilder
      def initialize(@title : String)
        @subtitle = ""
        @speaker = "Ian Rash (sol.vin)"
        @target_duration_seconds = 1800
        @qa_buffer_seconds = 180
        @chapters = [] of Core::KeynoteChapterSpec
        @qa_items = [] of Core::QaDefenseItem
      end

      def subtitle(sub : String)
        @subtitle = sub
        self
      end

      def speaker(spk : String)
        @speaker = spk
        self
      end

      def target_duration(seconds : Int32 = 1800)
        @target_duration_seconds = seconds
        self
      end

      def qa_buffer(seconds : Int32 = 180)
        @qa_buffer_seconds = seconds
        self
      end

      def act(number : Int32, title : String, from start_s : Int32, to end_s : Int32, purpose : String = "", &block : ChapterBuilder ->)
        builder = ChapterBuilder.new(number, title, start_s, end_s, purpose)
        yield builder
        @chapters << builder.build
        self
      end

      def qa(question : String, category : String, short_ans : String, deep_dive : String, trap : String)
        @qa_items << Core::QaDefenseItem.new(question, category, short_ans, deep_dive, trap)
        self
      end

      def build : Core::KeynoteChoreographySpec
        Core::KeynoteChoreographySpec.new(
          @title,
          @subtitle,
          @speaker,
          @target_duration_seconds,
          @qa_buffer_seconds,
          @chapters,
          @qa_items
        )
      end
    end

    # Module-level factory methods
    def self.cfp(title : String, &block : CfpBuilder ->) : Core::CfpSubmissionSpec
      builder = CfpBuilder.new(title)
      yield builder
      builder.build
    end

    def self.keynote(title : String, &block : KeynoteBuilder ->) : Core::KeynoteChoreographySpec
      builder = KeynoteBuilder.new(title)
      yield builder
      builder.build
    end
  end
end
