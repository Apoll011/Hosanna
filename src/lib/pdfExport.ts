

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


function translateElement(element: string) {
  switch (element) {
    case 'welcome':
      return 'Boas Vindas';
    case 'scripture':
      return 'Passagem';
    case 'message':
      return 'Pregação';
    case 'reading':
      return 'Leitura';
    case 'announcement':
      return 'Anuncio';
    case 'custom':
      return 'Customizado';
    default:
      return 'Elemento';
  }
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
    doc.setFillColor(2, 132, 199); // Theme primary cyan (#0284c7)
    doc.rect(marginX, marginY, contentWidth, 1.5, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(14);
    doc.setTextColor(7, 89, 133);
    doc.text(title.toUpperCase(), marginX, marginY + 7);

    if (subtitle) {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(9);
      doc.setTextColor(100, 116, 139);
      doc.text(subtitle, marginX, marginY + 12);
    }

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
    doc.setTextColor(148, 163, 184);
    
    const footerText = `Pauta de Culto  |  Gerado em ${new Date().toLocaleDateString('pt-PT')}`;
    const pageText = `Página ${currentPageNum}`;
    
    doc.text(footerText, marginX, pageHeight - 10);
    doc.text(pageText, pageWidth - marginX - doc.getTextWidth(pageText), pageHeight - 10);
  };

  // Build unified items list (songs and elements)
  const unifiedItems: Array<{
    kind: 'song' | 'element';
    song?: Song & { isMissing?: boolean };
    element?: any;
    position: number;
    notes?: string;
  }> = [];

  // Add songs
  songsList.forEach((song, idx) => {
    const customNote = (service.elements?.[idx]?.type === 'song' ? service.elements[idx].notes : '') || '';
    unifiedItems.push({
      kind: 'song',
      song,
      position: idx,
      notes: customNote,
    });
  });

  // Add elements
  (service.elements || []).forEach((elem, idx) => {
    unifiedItems.push({
      kind: 'element',
      element: elem,
      position: elem.position !== undefined ? elem.position : idx,
    });
  });

  // Sort unified items by position
  unifiedItems.sort((a, b) => a.position - b.position);

  // ================= PAGE 1: SERVICE SETLIST SUMMARY =================
  drawPageHeader('Pauta de Culto', service.name);
  
  let currentY = marginY + 18;

  // Metadata Info Box (Date & Overall Notes)
  doc.setFillColor(241, 245, 249);
  doc.setDrawColor(226, 232, 240);
  doc.roundedRect(marginX, currentY, contentWidth, 22, 2, 2, 'FD');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(15, 23, 42);
  doc.text('INFORMAÇÃO GERAL', marginX + 4, currentY + 5);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(71, 85, 105);
  doc.text(`Data: ${formatDate(service.date)}`, marginX + 4, currentY + 11);
  doc.text(`Total de Itens: ${unifiedItems.length} (${songsList.length} cânticos, ${(service.elements || []).length} elementos)`, marginX + 4, currentY + 16);

  // Overall Notes
  if (service.notes) {
    doc.setFont('helvetica', 'bold');
    doc.text('Notas / Avisos:', marginX + 85, currentY + 5);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);
    
    const splitNotes = doc.splitTextToSize(service.notes, contentWidth - 95);
    const maxLines = Math.min(splitNotes.length, 3);
    for (let i = 0; i < maxLines; i++) {
      doc.text(splitNotes[i], marginX + 85, currentY + 11 + (i * 4.5));
    }
  } else {
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(148, 163, 184);
    doc.text('Nenhuma nota geral adicionada a este culto.', marginX + 85, currentY + 11);
  }

  currentY += 28;

  // Setlist Table Header
  doc.setFillColor(2, 132, 199);
  doc.rect(marginX, currentY, contentWidth, 7, 'F');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8.5);
  doc.setTextColor(255, 255, 255);
  
  doc.text('#', marginX + 3, currentY + 4.8);
  doc.text('ITEM / CÂNTICO', marginX + 10, currentY + 4.8);
  doc.text('TIPO', marginX + 90, currentY + 4.8);
  doc.text('TOM / DETALHE', marginX + 120, currentY + 4.8);
  doc.text('ARRANJO / PASTA', marginX + 155, currentY + 4.8);

  currentY += 7;

  // Setlist Table Rows
  unifiedItems.forEach((item, idx) => {
    if (idx % 2 === 0) {
      doc.setFillColor(248, 250, 252);
    } else {
      doc.setFillColor(255, 255, 255);
    }
    
    const hasNote = item.kind === 'song' ? (item.notes && item.notes.trim().length > 0) : (item.element?.content && item.element.content.trim().length > 0);
    const rowHeight = hasNote ? 12 : 8;

    if (currentY + rowHeight > pageHeight - 20) {
      drawPageFooter();
      doc.addPage();
      currentPageNum++;
      currentY = marginY + 15;
      drawPageHeader('Pauta de Culto - Continuação', service.name);
      
      doc.setFillColor(2, 132, 199);
      doc.rect(marginX, currentY, contentWidth, 7, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8.5);
      doc.setTextColor(255, 255, 255);
      doc.text('#', marginX + 3, currentY + 4.8);
      doc.text('ITEM / CÂNTICO', marginX + 10, currentY + 4.8);
      doc.text('TIPO', marginX + 90, currentY + 4.8);
      doc.text('TOM / DETALHE', marginX + 120, currentY + 4.8);
      doc.text('ARRANJO / PASTA', marginX + 155, currentY + 4.8);
      currentY += 7;
    }

    doc.rect(marginX, currentY, contentWidth, rowHeight, 'F');
    doc.setDrawColor(241, 245, 249);
    doc.line(marginX, currentY + rowHeight, marginX + contentWidth, currentY + rowHeight);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(15, 23, 42);
    doc.text((idx + 1).toString(), marginX + 3, currentY + 5);

    if (item.kind === 'song') {
      const song = item.song!;
      if (song.isMissing) {
        doc.setTextColor(239, 68, 68);
        doc.text(song.title, marginX + 10, currentY + 5);
      } else {
        doc.text(song.title, marginX + 10, currentY + 5);
      }

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8.5);
      doc.setTextColor(100, 116, 139);
      doc.text(song.artist || 'Artista desconhecido', marginX + 10, currentY + 8.5);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8);
      doc.setTextColor(2, 132, 199);
      doc.text('CÂNTICO', marginX + 90, currentY + 5);

      const ast = !song.isMissing && song.content ? parseChordPro(song.content) : null;
      const baseKey = ast?.metadata.key || song.key || '-';
      const offset = transposeOffsets[song.id] || 0;
      const finalKey = (offset === 0 || baseKey === '-') ? baseKey : transposeChord(baseKey, offset);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(2, 132, 199);
      doc.text(finalKey, marginX + 120, currentY + 5.5);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(71, 85, 105);
      doc.text(truncateText(doc, song.folder || 'Raiz', 35), marginX + 155, currentY + 5);

      if (hasNote) {
        doc.setFont('helvetica', 'italic');
        doc.setFontSize(7.5);
        doc.setTextColor(7, 89, 133);
        doc.text(`Arr.: ${truncateText(doc, item.notes!, 110)}`, marginX + 10, currentY + 11);
      }
    } else {
      const elem = item.element!;
      doc.setTextColor(15, 23, 42);
      doc.text(elem.title || 'Elemento', marginX + 10, currentY + 5);

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8);
      doc.setTextColor(192, 38, 211); // Fuchsia/purple for elements
      doc.text(translateElement(elem.type as string), marginX + 90, currentY + 5);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(100, 116, 139);
      doc.text('-', marginX + 120, currentY + 5.5);

      if (hasNote) {
        doc.setFont('helvetica', 'italic');
        doc.setFontSize(7.5);
        doc.setTextColor(100, 116, 139);
        doc.text(`Conteúdo: ${truncateText(doc, elem.content, 110)}`, marginX + 10, currentY + 11);
      }
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
      const songNote = (service.elements?.[idx]?.type === 'song' ? service.elements[idx].notes : '') || '';
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
