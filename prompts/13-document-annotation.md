# Document Annotation

Systematically transcribe and annotate a batch of scanned genealogical documents, producing structured vault notes ready for client delivery.

## Autoresearch Configuration

**Goal**: For every scanned document in `[SCAN_PATH]`, classify the document type, transcribe its text using the appropriate OCR method, extract key genealogical facts into a structured table, and save a completed vault note using the correct template from `[VAULT_PATH]/templates/`. Set `client: [CLIENT]` and `deliverable: true` in every note. At the end of the batch, generate a summary index file.

**Metric**: Number of scanned documents with a completed vault note (transcription present, Extracted Facts table populated, Commentary section written, `reviewed: false` set)

**Direction**: Maximize

**Verify**: Count `.md` files in `[VAULT_PATH]` with `deliverable: true` in their frontmatter. Before starting, run:
```
grep -rl "deliverable: true" [VAULT_PATH] | wc -l
```
Record this as the baseline. Report the delta after each iteration.

**Guard**:
- Do not fabricate text. Transcribe only what is visible in the image.
- Mark every illegible word or phrase with `[unclear]`. Do not guess at illegible text without flagging it.
- Do not infer facts that are not directly stated in the document. Inferences belong in the Commentary section, clearly labeled as such.
- Do not alter the client name, dates, or names already present in the vault.
- Do not delete or overwrite existing vault notes.

**Iterations**: 6

**Protocol**:

Each iteration processes one document (or one logical group of related documents, such as front and back of the same postcard).

1. **Select the next unprocessed document**: Read the file listing in `[SCAN_PATH]`. Skip any file that already has a corresponding vault note. Pick the next image file (jpg, png, tif, pdf).

2. **Classify the document**: Determine the document type:
   - **Certificate**: birth, marriage, death, baptism, confirmation, military, naturalization
   - **Newspaper**: clipping, obituary, announcement
   - **Letter**: typed or handwritten personal correspondence
   - **Postcard**: image on front, message on back
   - **Military**: discharge papers, draft registration, pension file
   - **Other**: any document not fitting the above

3. **Choose OCR method**:
   - Printed text (certificates, typed letters, newspaper clippings): use Tesseract
     ```bash
     tesseract [image_path] output_text -l [language_code]
     ```
   - Handwritten text, old scripts (Kurrent, Fraktur), or damaged/faded documents: use Claude multimodal
     ```
     Read the file at [image_path] and transcribe all visible text. Mark illegible
     portions with [unclear]. This is a [document_type] from approximately [date]
     in [language].
     ```
   - Mixed (e.g., printed form filled in by hand): run Tesseract for the printed portions, then Claude multimodal for handwritten fill-in. Merge the results.

4. **Create the vault note**: Choose the correct template:
   - Certificates: copy `[VAULT_PATH]/templates/certificate.md`
   - Postcards: copy `[VAULT_PATH]/templates/postcard.md`
   - All other documents: copy `[VAULT_PATH]/templates/transcription.md`

   Fill in the frontmatter:
   - `source`: path to the scan file
   - `document_type`: from step 2
   - `person`: names found in the document
   - `date`: date on the document (YYYY-MM-DD where possible; approximate if needed)
   - `created`: today's date
   - `ocr_method`: method used in step 3
   - `ocr_quality`: good / partial / bad (grade the output honestly)
   - `client`: [CLIENT]
   - `deliverable`: true
   - `reviewed`: false

   Name the file descriptively: `Transcription_[DocumentType]_[PersonSurname]_[Year].md`

5. **Write the transcription**: Paste the full OCR output into the Transcription section. Preserve original layout, spelling, and punctuation. Do not correct errors in the original.

6. **Extract facts**: Populate the Extracted Facts table. For each fact, assign a confidence level:
   - **High**: directly and clearly stated in the document
   - **Moderate**: legible but requires some interpretation (faded, abbreviated, variant spelling)
   - **Low**: reconstructed from partial text; flag with `[unclear]` in the Value column

7. **Write the Commentary section**: Add a section at the end of the note titled `## Commentary`. Include:
   - Document condition and any preservation concerns
   - Handwriting or printing quality assessment
   - Language notes (if not English)
   - Relationship of the document to the family line being researched
   - Any discrepancies between this document and other sources already in the vault
   - Suggested next research steps this document opens up (e.g., "Death certificate names county of origin; search church records for [Location]")
   - For certificates: note whether the filing date differs significantly from the event date, and assess informant reliability
   - For postcards: note what the content reveals about relationships or movements
   - Clearly label any inference: "Inference: ..." rather than stating it as fact

8. **Update the Research Log**: In `[VAULT_PATH]/Research_Log.md`, add one line per document:
   ```
   [Date] | [Document type] | [Person(s)] | [File name] | [OCR quality] | [Key fact extracted]
   ```

9. **Move to the next document**: Return to step 1.

**Final iteration (after all documents are processed)**:

Generate a batch summary index file at `[VAULT_PATH]/Document_Batch_[YYYY-MM-DD].md`:

```markdown
---
type: index
created: YYYY-MM-DD
client: [CLIENT]
tags: [genealogy, index, batch]
---

# Document Batch: [YYYY-MM-DD]

| File | Document Type | Person(s) | Date | OCR Quality | Key Fact |
|---|---|---|---|---|---|
| [[note_name]] | [type] | [names] | [date] | [quality] | [one-line summary] |
```

Also update the baseline count in `[VAULT_PATH]/Research_Log.md` and report the total delta.

## Tips

- **Batch by document type**: Processing all certificates before moving to letters reduces context-switching and improves consistency.
- **Foreign language documents**: Note the language in the `Commentary` section. If translation is needed, flag it: "Translation required: document is in [language]."
- **Poor scan quality**: If OCR produces garbage on the first attempt, try ImageMagick preprocessing before retrying:
  ```bash
  convert input.jpg -colorspace Gray -normalize -sharpen 0x1 preprocessed.jpg
  ```
- **Duplicate documents**: If two scans appear to be the same document (e.g., front and back photographed separately), combine them into a single vault note.
- **Relationship to person files**: If a document provides new information about a person who already has a person file in the vault, add a link in that person file's Document Sources table.
- **Confidence tiers**: Use Strong Signal / Moderate Signal / Speculative only in the Commentary section when assessing research value. Use High / Moderate / Low in the Extracted Facts table for individual field confidence.
