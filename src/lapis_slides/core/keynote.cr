require "../codex"

module LapisSlides
  module Core
    enum StageCueType
      SlideAdvance
      TerminalDemo
      GodotEditorDemo
      CodeHighlight
      AudiencePause
      KeyEmphasis
      DisassemblyInspect
    end

    struct StageCue
      getter cue_type : StageCueType
      getter timestamp_seconds : Int32
      getter target_ref : String
      getter instruction : String

      def initialize(
        @cue_type : StageCueType,
        @timestamp_seconds : Int32,
        @target_ref : String,
        @instruction : String = ""
      )
      end

      def formatted_timestamp : String
        sprintf("%02d:%02d", @timestamp_seconds // 60, @timestamp_seconds % 60)
      end
    end

    struct KeynoteBeatSpec
      getter id : String
      getter title : String
      getter start_second : Int32
      getter end_second : Int32
      getter slide_ids : Array(String)
      getter hook : String
      getter spoken_script : String
      getter stage_cues : Array(StageCue)
      getter visual_callouts : Array(String)
      getter key_insight : String
      getter tone_direction : String

      def initialize(
        @id : String,
        @title : String,
        @start_second : Int32,
        @end_second : Int32,
        @slide_ids : Array(String) = [] of String,
        @hook : String = "",
        @spoken_script : String = "",
        @stage_cues : Array(StageCue) = [] of StageCue,
        @visual_callouts : Array(String) = [] of String,
        @key_insight : String = "",
        @tone_direction : String = "Confident, technical, conversational"
      )
      end

      def duration_seconds : Int32
        @end_second - @start_second
      end

      def word_count : Int32
        @spoken_script.split(/\s+/).reject(&.empty?).size
      end

      def words_per_minute : Float64
        duration_seconds > 0 ? (word_count.to_f / duration_seconds) * 60.0 : 0.0
      end

      def formatted_time : String
        sprintf("%02d:%02d - %02d:%02d", @start_second // 60, @start_second % 60, @end_second // 60, @end_second % 60)
      end
    end

    struct KeynoteChapterSpec
      getter act_number : Int32
      getter act_name : String
      getter title : String
      getter start_second : Int32
      getter end_second : Int32
      getter narrative_purpose : String
      getter beats : Array(KeynoteBeatSpec)

      def initialize(
        @act_number : Int32,
        @act_name : String,
        @title : String,
        @start_second : Int32,
        @end_second : Int32,
        @narrative_purpose : String,
        @beats : Array(KeynoteBeatSpec) = [] of KeynoteBeatSpec
      )
      end

      def duration_seconds : Int32
        @end_second - @start_second
      end

      def total_words : Int32
        @beats.sum(&.word_count)
      end

      def formatted_time : String
        sprintf("%02d:%02d - %02d:%02d", @start_second // 60, @start_second % 60, @end_second // 60, @end_second % 60)
      end
    end

    struct QaDefenseItem
      getter question : String
      getter category : String
      getter short_punchy_answer : String
      getter technical_deep_dive : String
      getter trap_to_avoid : String

      def initialize(
        @question : String,
        @category : String,
        @short_punchy_answer : String,
        @technical_deep_dive : String,
        @trap_to_avoid : String
      )
      end
    end

    struct KeynoteChoreographySpec
      getter title : String
      getter subtitle : String
      getter speaker : String
      getter target_duration_seconds : Int32
      getter qa_buffer_seconds : Int32
      getter chapters : Array(KeynoteChapterSpec)
      getter qa_items : Array(QaDefenseItem)

      def initialize(
        @title : String,
        @subtitle : String = "",
        @speaker : String = "Ian Rash (sol.vin)",
        @target_duration_seconds : Int32 = 1800, # 30 minutes
        @qa_buffer_seconds : Int32 = 180,        # 3 minutes
        @chapters : Array(KeynoteChapterSpec) = [] of KeynoteChapterSpec,
        @qa_items : Array(QaDefenseItem) = [] of QaDefenseItem
      )
      end

      def total_actual_seconds : Int32
        @chapters.empty? ? 0 : @chapters.last.end_second
      end

      def total_word_count : Int32
        @chapters.sum(&.total_words)
      end

      def average_wpm : Float64
        total_actual_seconds > 0 ? (total_word_count.to_f / total_actual_seconds) * 60.0 : 0.0
      end

      def all_beats : Array(KeynoteBeatSpec)
        @chapters.flat_map(&.beats)
      end

      def all_cues : Array(StageCue)
        all_beats.flat_map(&.stage_cues)
      end
    end

    struct ChoreographyValidationError
      getter field : String
      getter message : String

      def initialize(@field : String, @message : String)
      end
    end

    class ChoreographyValidator
      def self.validate(ch : KeynoteChoreographySpec) : Array(ChoreographyValidationError)
        errors = [] of ChoreographyValidationError

        if ch.chapters.empty?
          errors << ChoreographyValidationError.new("chapters", "Choreography must contain at least one chapter/act")
          return errors
        end

        # Check total duration
        if ch.total_actual_seconds != ch.target_duration_seconds
          errors << ChoreographyValidationError.new(
            "total_duration",
            "Total actual duration (#{ch.total_actual_seconds}s / #{ch.total_actual_seconds // 60}m#{ch.total_actual_seconds % 60}s) does not match target (#{ch.target_duration_seconds}s / #{ch.target_duration_seconds // 60}m)"
          )
        end

        # Check chapter continuity
        expected_sec = 0
        ch.chapters.each_with_index do |chap, idx|
          if chap.start_second != expected_sec
            errors << ChoreographyValidationError.new(
              "chapter[#{idx}].start_second",
              "Chapter #{chap.act_number} begins at #{chap.start_second}s, expected continuous start at #{expected_sec}s"
            )
          end
          if chap.end_second <= chap.start_second
            errors << ChoreographyValidationError.new(
              "chapter[#{idx}].end_second",
              "Chapter #{chap.act_number} end_second (#{chap.end_second}) must be greater than start_second (#{chap.start_second})"
            )
          end
          expected_sec = chap.end_second

          # Check beat continuity within chapter
          beat_expected_sec = chap.start_second
          chap.beats.each_with_index do |b, b_idx|
            if b.start_second != beat_expected_sec
              errors << ChoreographyValidationError.new(
                "chapter[#{idx}].beat[#{b_idx}].start_second",
                "Beat '#{b.id}' starts at #{b.start_second}s, expected #{beat_expected_sec}s"
              )
            end
            if b.end_second <= b.start_second
              errors << ChoreographyValidationError.new(
                "chapter[#{idx}].beat[#{b_idx}].end_second",
                "Beat '#{b.id}' end_second (#{b.end_second}) must exceed start_second (#{b.start_second})"
              )
            end
            beat_expected_sec = b.end_second

            # Check WPM sanity (warn/error if too fast > 180 or too slow < 75)
            if b.words_per_minute > 185.0
              errors << ChoreographyValidationError.new(
                "chapter[#{idx}].beat[#{b_idx}].wpm",
                "Beat '#{b.id}' pacing too fast: #{b.words_per_minute.round(1)} WPM (max 180 WPM)"
              )
            end
          end

          if !chap.beats.empty? && chap.beats.last.end_second != chap.end_second
            errors << ChoreographyValidationError.new(
              "chapter[#{idx}].beats",
              "Final beat end (#{chap.beats.last.end_second}s) does not match chapter end (#{chap.end_second}s)"
            )
          end
        end

        errors
      end
    end

    class KeynoteCompiler
      def self.emit_markdown(ch : KeynoteChoreographySpec) : String
        String.build do |io|
          io << "# 30-Minute Keynote Choreography & Script — " << ch.title << "\n\n"
          io << "> **Subtitle**: " << ch.subtitle << "  \n"
          io << "> **Speaker**: " << ch.speaker << "  \n"
          io << "> **Target Duration**: " << (ch.target_duration_seconds // 60) << ":00 (" << ch.target_duration_seconds << "s) | "
          io << "**Total Word Count**: " << ch.total_word_count << " words | "
          io << "**Average Pacing**: " << ch.average_wpm.round(1) << " WPM\n\n"
          io << "---\n\n"

          io << "## 1. Executive Keynote Summary & Presentation Arc\n\n"
          io << "| Act | Title | Timing Window | Duration | Target Slides | Tone & Energy |\n"
          io << "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
          ch.chapters.each do |c|
            slide_count = c.beats.flat_map(&.slide_ids).uniq.size
            slide_range = c.beats.flat_map(&.slide_ids).first? ? "#{c.beats.flat_map(&.slide_ids).first}–#{c.beats.flat_map(&.slide_ids).last}" : "N/A"
            io << "| **Act " << c.act_number << "** | " << c.title << " | `" << c.formatted_time << "` | " << (c.duration_seconds // 60) << "m " << (c.duration_seconds % 60) << "s | " << slide_count << " slides (`" << slide_range << "`) | " << c.narrative_purpose << " |\n"
          end
          io << "\n"

          io << "## 2. Pacing Milestones & Rehearsal Checkpoints\n\n"
          io << "- `05:00` Checkpoint: End of Act I & Transition to Crystal GDExtension architecture.\n"
          io << "- `10:00` Checkpoint: Live demo of Declarative DSL & Node definitions.\n"
          io << "- `15:00` Checkpoint (Halfway): AST Macro expansion & signal arity trimming complete.\n"
          io << "- `20:00` Checkpoint: GC analysis, zero-allocation loops, and radare2 disassembly.\n"
          io << "- `25:00` Checkpoint: Hard 100k transform benchmarks and frame-pacing graphs.\n"
          io << "- `27:00` Checkpoint: Sol-Vin ecosystem, open-source roadmap, and call-to-action.\n"
          io << "- `27:00 - 30:00`: Audience Q&A Reserve buffer (3 minutes).\n\n"

          io << "---\n\n"
          io << "## 3. Choreographed Script (Slide-by-Slide & Cue-by-Cue)\n\n"

          ch.chapters.each do |chap|
            io << "### Act " << chap.act_number << ": " << chap.title << " (`" << chap.formatted_time << "`)\n\n"
            io << "> **Narrative Objective**: " << chap.narrative_purpose << "  \n"
            io << "> **Budget**: " << (chap.duration_seconds // 60) << "m " << (chap.duration_seconds % 60) << "s | "
            io << "**Words**: " << chap.total_words << " (" << ((chap.total_words.to_f / chap.duration_seconds) * 60.0).round(1) << " WPM)\n\n"

            chap.beats.each_with_index do |beat, b_idx|
              io << "#### " << chap.act_number << "." << (b_idx + 1) << " " << beat.title << " (`" << beat.formatted_time << "`)\n\n"
              io << "- **Slide(s)**: `" << beat.slide_ids.join("`, `") << "`\n"
              io << "- **Opening Hook**: *" << beat.hook << "*\n"
              io << "- **Key Insight**: " << beat.key_insight << "\n"
              io << "- **Tone Direction**: " << beat.tone_direction << "\n"
              io << "- **Pacing**: " << beat.word_count << " words (~" << beat.words_per_minute.round(1) << " WPM)\n\n"

              unless beat.visual_callouts.empty?
                io << "**Visual Callouts & Slide Focus**:\n"
                beat.visual_callouts.each { |vc| io << "- " << vc << "\n" }
                io << "\n"
              end

              unless beat.stage_cues.empty?
                io << "**Stage & AV Cues**:\n"
                beat.stage_cues.each do |cue|
                  io << "- `[" << cue.formatted_timestamp << "]` **" << cue.cue_type << "** &rarr; `" << cue.target_ref << "`: *" << cue.instruction << "*\n"
                end
                io << "\n"
              end

              io << "**Spoken Script (Teleprompter)**:\n\n"
              io << beat.spoken_script.strip << "\n\n"
              io << "---\n\n"
            end
          end

          io << "## 4. Audience Q&A Defense Playbook (Anticipated Questions & Traps)\n\n"
          ch.qa_items.each_with_index do |qa, idx|
            io << "### Q" << (idx + 1) << " [" << qa.category << "]: \"" << qa.question << "\"\n\n"
            io << "**Short Punchy Answer (15 Seconds)**:\n> *" << qa.short_punchy_answer << "*\n\n"
            io << "**Technical Deep Dive Defense**:\n" << qa.technical_deep_dive << "\n\n"
            io << "**Trap to Avoid**: :warning: *" << qa.trap_to_avoid << "*\n\n"
            io << "---\n\n"
          end

          io << "## 5. Speaker Checklist & AV Invariants\n\n"
          io << "- [ ] **Resolution**: 1920x1080 (16:9 fixed ratio).\n"
          io << "- [ ] **Color Contrast**: Dark background (`#0e1117`) with high-contrast text (`#ffffff` / `#10b981`).\n"
          io << "- [ ] **Fonts**: JetBrains Mono for code; Inter / sans-serif for headings.\n"
          io << "- [ ] **Demo Fallback**: Screen recording video backup (`crystalmeme.mp4`) pre-loaded if live Godot editor freezes.\n"
          io << "- [ ] **Pointer / Clicker**: Tested forward/back buttons; presenter timer set to 30:00 countdown.\n"
          io << "- [ ] **Audio**: Lav mic positioned 4 inches below chin; water bottle within reach on podium.\n"
        end
      end
    end
  end
end
