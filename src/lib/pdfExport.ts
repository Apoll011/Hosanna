/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { jsPDF } from 'jspdf';
import { Service, Song } from '../types';
import { parseChordPro, transposeChord } from './chordpro';

/**
 * Helper to fetch /logo.png and convert to base64 at runtime in browser
 */
function getLogoBase64(): Promise<string | null> {
  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.src = '/logo.png';
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.drawImage(img, 0, 0);
          resolve(canvas.toDataURL('image/png'));
          return;
        }
      } catch (e) {
        console.error("Canvas conversion failed", e);
      }
      resolve(null);
    };
    img.onerror = () => {
      resolve(null);
    };
  });
}

/**
 * Formats YYYY-MM-DD date into DD/MM/YYYY
 */
function formatDate(dateStr: string): string {
  if (!dateStr) return '';
  const parts = dateStr.split('-');
  if (parts.length === 3) {
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
  return dateStr;
}

/**
 * Truncates text to fit a maximum width in jsPDF
 */
function truncateText(doc: jsPDF, text: string, maxWidth: number): string {
  if (doc.getTextWidth(text) <= maxWidth) return text;
  
  let truncated = text;
  while (truncated.length > 0 && doc.getTextWidth(truncated + '...') > maxWidth) {
    truncated = truncated.slice(0, -1);
  }
  return truncated + '...';
}

/**
 * Generates and downloads a beautifully formatted PDF for the service setlist.
 */
export async function exportServiceToPDF(
  service: Service,
  songsList: (Song & { isMissing?: boolean })[],
  options: { includeChords: boolean; transposeOffsets?: Record<string, number> }
): Promise<void> {
  const { includeChords, transposeOffsets = {} } = options;
  const logoDataUrl = await getLogoBase64();

  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4',
  });

  const pageHeight = 297;
  const pageWidth = 210;
  const marginX = 15;
  const marginY = 15;
  const contentWidth = pageWidth - (marginX * 2);

  let currentPageNum = 1;

  // Header Helper
  const drawPageHeader = (title: string, subtitle?: string) => {
    // Elegant accent header line
    doc.setFillColor(2, 132, 199); // Theme primary cyan (#0284c7)
    doc.rect(marginX, marginY, contentWidth, 1.5, 'F');

    // Title
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.setTextColor(7, 89, 133); // Theme primary dark cyan (#075985)
    doc.text(title.toUpperCase(), marginX, marginY + 7);

    // Subtitle
    if (subtitle) {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(9);
      doc.setTextColor(100, 116, 139); // Slate secondary
      doc.text(subtitle, marginX, marginY + 12);
    }

    // Logo embedding
    if (logoDataUrl) {
      try {
        doc.addImage(logoDataUrl, 'PNG', pageWidth - marginX - 10, marginY + 2.2, 10, 10);
      } catch (err) {
        console.error("Failed to add logo to PDF", err);
      }
    }
  };

  // Footer Helper
  const drawPageFooter = () => {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(148, 163, 184); // Light grey text
    
    const footerText = `Pauta de Culto  |  Gerado em ${new Date().toLocaleDateString('pt-PT')}`;
    const pageText = `Página ${currentPageNum}`;
    
    doc.text(footerText, marginX, pageHeight - 10);
    doc.text(pageText, pageWidth - marginX - doc.getTextWidth(pageText), pageHeight - 10);
  };

  // ================= PAGE 1: SERVICE SETLIST SUMMARY =================
  drawPageHeader('Pauta de Culto', service.name);
  
  let currentY = marginY + 18;

  // Metadata Info Box (Date & Overall Notes)
  doc.setFillColor(241, 245, 249); // slate-100
  doc.setDrawColor(226, 232, 240); // slate-200
  doc.roundedRect(marginX, currentY, contentWidth, 22, 2, 2, 'FD');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(15, 23, 42); // slate-900
  doc.text('INFORMAÇÃO GERAL', marginX + 4, currentY + 5);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(71, 85, 105); // slate-600
  doc.text(`Data: ${formatDate(service.date)}`, marginX + 4, currentY + 11);
  doc.text(`Total de Cânticos: ${songsList.length}`, marginX + 4, currentY + 16);

  // Overall Notes (if any)
  if (service.notes) {
    doc.setFont('helvetica', 'bold');
    doc.text('Notas / Avisos:', marginX + 75, currentY + 5);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);
    
    const splitNotes = doc.splitTextToSize(service.notes, contentWidth - 85);
    // Draw up to 3 lines
    const maxLines = Math.min(splitNotes.length, 3);
    for (let i = 0; i < maxLines; i++) {
      doc.text(splitNotes[i], marginX + 75, currentY + 11 + (i * 4.5));
    }
  } else {
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(148, 163, 184);
    doc.text('Nenhuma nota geral adicionada a este culto.', marginX + 75, currentY + 11);
  }

  currentY += 28;

  // Setlist Table Header
  doc.setFillColor(2, 132, 199); // Theme primary cyan (#0284c7)
  doc.rect(marginX, currentY, contentWidth, 7, 'F');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8.5);
  doc.setTextColor(255, 255, 255); // White text
  
  doc.text('#', marginX + 3, currentY + 4.8);
  doc.text('CÂNTICO', marginX + 10, currentY + 4.8);
  doc.text('TOM', marginX + 100, currentY + 4.8);
  doc.text('BPM', marginX + 118, currentY + 4.8);
  doc.text('PASTA / ARRANJO', marginX + 135, currentY + 4.8);

  currentY += 7;

  // Setlist Table Rows
  songsList.forEach((song, idx) => {
    // Alternating background colors
    if (idx % 2 === 0) {
      doc.setFillColor(248, 250, 252); // slate-50
    } else {
      doc.setFillColor(255, 255, 255); // White
    }
    
    // Check height for notes
    const customNote = service.songNotes?.[idx.toString()] || '';
    const hasNote = customNote.trim().length > 0;
    const rowHeight = hasNote ? 12 : 8;

    // Check page break for safety (unlikely on page 1, but good practice)
    if (currentY + rowHeight > pageHeight - 20) {
      drawPageFooter();
      doc.addPage();
      currentPageNum++;
      currentY = marginY + 15;
      drawPageHeader('Pauta de Culto - Continuação', service.name);
      
      // Draw Table Header again
      doc.setFillColor(2, 132, 199);
      doc.rect(marginX, currentY, contentWidth, 7, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8.5);
      doc.setTextColor(255, 255, 255);
      doc.text('#', marginX + 3, currentY + 4.8);
      doc.text('CÂNTICO', marginX + 10, currentY + 4.8);
      doc.text('TOM', marginX + 100, currentY + 4.8);
      doc.text('BPM', marginX + 118, currentY + 4.8);
      doc.text('PASTA / ARRANJO', marginX + 135, currentY + 4.8);
      currentY += 7;
    }

    doc.rect(marginX, currentY, contentWidth, rowHeight, 'F');

    // Row borders
    doc.setDrawColor(241, 245, 249);
    doc.line(marginX, currentY + rowHeight, marginX + contentWidth, currentY + rowHeight);

    // Row Content
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(15, 23, 42); // slate-900
    doc.text((idx + 1).toString(), marginX + 3, currentY + 5);

    if (song.isMissing) {
      doc.setTextColor(239, 68, 68); // Red
      doc.text(song.title, marginX + 10, currentY + 5);
    } else {
      doc.text(song.title, marginX + 10, currentY + 5);
    }

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.5);
    doc.setTextColor(100, 116, 139); // slate-500
    doc.text(song.artist || 'Artista desconhecido', marginX + 10, currentY + 8.5);

    // Compute Transposed Key
    const ast = !song.isMissing && song.content ? parseChordPro(song.content) : null;
    const baseKey = ast?.metadata.key || song.key || '-';
    const offset = transposeOffsets[song.id] || 0;
    const finalKey = (offset === 0 || baseKey === '-') 
      ? baseKey 
      : transposeChord(baseKey, offset);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9.5);
    doc.setTextColor(2, 132, 199); // Theme primary cyan (#0284c7)
    doc.text(finalKey, marginX + 100, currentY + 5.5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(15, 23, 42);
    doc.text(ast?.metadata.tempo || song.tempo || '-', marginX + 118, currentY + 5.5);

    doc.setFontSize(8);
    doc.setTextColor(71, 85, 105);
    doc.text(truncateText(doc, song.folder || 'Raiz', 45), marginX + 135, currentY + 5);

    // If has custom arrangement note
    if (hasNote) {
      doc.setFont('helvetica', 'italic');
      doc.setFontSize(7.5);
      doc.setTextColor(7, 89, 133); // Theme primary dark cyan
      doc.text(`Arr.: ${truncateText(doc, customNote, 110)}`, marginX + 10, currentY + 11);
    }

    currentY += rowHeight;
  });

  drawPageFooter();

  // ================= SUBSEQUENT PAGES: CHORD SHEETS =================
  if (includeChords) {
    songsList.forEach((song, idx) => {
      if (song.isMissing || !song.content) return; // Skip missing songs

      doc.addPage();
      currentPageNum++;

      // Compute Transposition
      const offset = transposeOffsets[song.id] || 0;
      const ast = parseChordPro(song.content);
      
      const origKey = ast.metadata.key || song.key || '-';
      const finalKey = (offset === 0 || origKey === '-') 
        ? origKey 
        : transposeChord(origKey, offset);

      const titleStr = `${idx + 1}. ${song.title}`;
      const metaStr = `Tom original: ${origKey}  |  Tom do culto: ${finalKey}  |  BPM: ${ast.metadata.tempo || song.tempo || 'N/A'}`;

      drawPageHeader(titleStr, metaStr);

      currentY = marginY + 18;

      // Custom band arrangement notes for this specific song
      const songNote = service.songNotes?.[idx.toString()] || '';
      if (songNote.trim().length > 0) {
        doc.setFillColor(240, 249, 255); // light cyan bg (#f0f9ff)
        doc.setDrawColor(186, 230, 253); // border-sky-200 (#bae6fd)
        doc.roundedRect(marginX, currentY, contentWidth, 10, 1.5, 1.5, 'FD');

        doc.setFont('helvetica', 'bold');
        doc.setFontSize(8);
        doc.setTextColor(3, 105, 161); // sky-700
        doc.text('NOTA DA BANDA:', marginX + 3, currentY + 6.2);

        doc.setFont('helvetica', 'italic');
        doc.setFontSize(8);
        doc.setTextColor(7, 89, 133);
        doc.text(truncateText(doc, songNote, contentWidth - 35), marginX + 30, currentY + 6.2);

        currentY += 14;
      }

      // Iterate through sections and lines
      ast.sections.forEach((section) => {
        // Prepare Section Header
        const secLabel = section.label || (section.type === 'chorus' ? 'REFRÃO' : section.type === 'tab' ? 'TABLATURA' : 'VERSO');
        
        // Check for page overflow
        if (currentY + 12 > pageHeight - 20) {
          drawPageFooter();
          doc.addPage();
          currentPageNum++;
          currentY = marginY + 15;
          drawPageHeader(`${song.title} (Continuação)`, metaStr);
        }

        // Draw Section Label
        doc.setFillColor(241, 245, 249); // light background for label
        doc.roundedRect(marginX, currentY, 40, 5, 1, 1, 'F');

        doc.setFont('helvetica', 'bold');
        doc.setFontSize(8);
        doc.setTextColor(2, 132, 199); // Theme primary cyan (#0284c7)
        doc.text(secLabel.toUpperCase(), marginX + 2, currentY + 3.8);

        currentY += 8;

        // Print lines in section
        section.lines.forEach((line) => {
          if (line.type === 'empty') {
            currentY += 4;
            return;
          }

          // Check overflow for individual lines
          const neededSpace = line.type === 'lyrics' ? 9 : 5;
          if (currentY + neededSpace > pageHeight - 20) {
            drawPageFooter();
            doc.addPage();
            currentPageNum++;
            currentY = marginY + 15;
            drawPageHeader(`${song.title} (Continuação)`, metaStr);
            
            // Repeat Section Label for context
            doc.setFillColor(241, 245, 249);
            doc.roundedRect(marginX, currentY, 40, 5, 1, 1, 'F');
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(8);
            doc.setTextColor(2, 132, 199);
            doc.text(`${secLabel.toUpperCase()} (CONT.)`, marginX + 2, currentY + 3.8);
            currentY += 8;
          }

          if (line.type === 'comment' && line.text) {
            doc.setFont('helvetica', 'italic');
            doc.setFontSize(8.5);
            doc.setTextColor(100, 116, 139); // Slate-500
            doc.text(line.text, marginX + 4, currentY + 3.5);
            currentY += 5.5;
          } 
          else if (line.type === 'tab' && line.text) {
            doc.setFont('courier', 'normal');
            doc.setFontSize(8);
            doc.setTextColor(71, 85, 105); // Slate-600
            doc.text(line.text, marginX + 4, currentY + 3);
            currentY += 5;
          } 
          else if (line.type === 'lyrics' && line.segments) {
            // Build the character-aligned chords and lyrics lines using courier
            let chordStr = '';
            let lyricsStr = '';
            let hasChords = false;

            line.segments.forEach((seg) => {
              const textLength = seg.text.length;
              let chord = seg.chord;

              // Transpose chord if required
              if (chord && offset !== 0) {
                chord = transposeChord(chord, offset);
              }

              if (chord) {
                hasChords = true;
                const currentLyricsLength = lyricsStr.length;
                if (currentLyricsLength > chordStr.length) {
                  chordStr = chordStr.padEnd(currentLyricsLength, ' ');
                }
                chordStr += chord;
              }
              lyricsStr += seg.text;
            });

            // Draw Chords line (only if there are chords in this line)
            if (hasChords && chordStr.trim().length > 0) {
              doc.setFont('courier', 'bold');
              doc.setFontSize(8.5);
              doc.setTextColor(2, 132, 199); // Theme primary cyan (#0284c7)
              doc.text(chordStr, marginX + 4, currentY + 3);
              currentY += 4.2;
            }

            // Draw Lyrics line
            doc.setFont('courier', 'normal');
            doc.setFontSize(8.5);
            doc.setTextColor(15, 23, 42); // slate-900
            doc.text(lyricsStr, marginX + 4, currentY + 3);
            currentY += 5;
          }
        });

        currentY += 4; // space after section
      });

      drawPageFooter();
    });
  }

  // Save the PDF
  const safeFilename = service.name.toLowerCase().replace(/[^a-z0-9]/g, '_');
  doc.save(`pauta_culto_${safeFilename}.pdf`);
}
