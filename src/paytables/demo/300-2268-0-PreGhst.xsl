<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioMainGameWinSymb = getMainGameWinSymb(scenario);
						var scenarioMainGameData = getMainGameData(scenario);
						var scenarioBonusGameData = getBonusGameData(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const symbWinners     = 'ABCD';
						const symbLosers      = 'EFGHIJ';
						const symbIWs         = 'XYZ';
						const symbQuantities  = '123';
						const symbBonusGame   = 'T';
						const symbBonusLosers = 'KLMNOPQR';

						var mgScore = scenarioMainGameData.replace(new RegExp('[^1-3]', 'g'), '').split("").map(function(item) {return parseInt(item,10);} ).reduce(function(a,b) {return a + b;}, 0);

						var mgInstantWins = scenarioMainGameData.replace(new RegExp('[^X-Z]', 'g'), '');

						var doMainGameWin = (mgScore >= 3);
						var doInstantWins = (mgInstantWins != '');
						var doBonusGame   = (scenarioMainGameData.indexOf(symbBonusGame) != -1);

						if (doBonusGame)
						{
							var lastTurn = scenarioBonusGameData[scenarioBonusGameData.length - 1];

							var bgScore = lastTurn.replace(new RegExp('[^1-3]', 'g'), '').split("").map(function(item) {return parseInt(item,10);} ).reduce(function(a,b) {return a + b;}, 0);
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const cellSize     = 36;
						const cellMargin   = 1;
						const cellTextX    = 19;
						const cellTextY    = 21;
						const colourBlack  = '#000000';
						const colourBlue   = '#99ccff';
						const colourLemon  = '#ffff99';
						const colourLilac  = '#ccccff';
						const colourLime   = '#ccff99';
						const colourOrange = '#ffcc99';
						const colourPurple = '#cc99ff';
						const colourRed    = '#ff9999';
						const colourWhite  = '#ffffff';

						const coloursWinSymb = [colourLemon, colourOrange, colourRed];
						const coloursIW      = [colourBlue, colourLilac, colourPurple];

						var r = [];

						var boxColourStr = '';
						var canvasIdStr  = '';
						var elementStr   = '';
						var symbDesc     = '';
						var symbPrize    = '';
						var symbQuantity = '';
						var symbQtyText  = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (cellSize + 2 * cellMargin).toString() + '" height="' + (cellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + cellTextX.toString() + ', ' + cellTextY.toString() + ');');

							r.push('</script>');
						}

						/////////////////////
						// Win Symbols Key //
						/////////////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleWinSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var symbIndex = 0; symbIndex < symbWinners.length; symbIndex++)
						{
							symbPrize    = symbWinners[symbIndex];
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'eleKeySymb' + symbPrize;
							symbDesc     = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						/////////////////////////////
						// Win Symbol Quantity Key //
						/////////////////////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleWinSymbolQuantityKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var quantityIndex = 0; quantityIndex < 3; quantityIndex++)
						{
							symbQuantity  = symbQuantities[quantityIndex];
							canvasIdStr   = 'cvsKeySymb' + symbQuantity;
							elementStr    = 'eleKeySymb' + symbQuantity;
							boxColourStr  = coloursWinSymb[quantityIndex];
							symbDesc      = 'symb' + symbQuantity;
							symbQtyText   = symbQuantities.slice(0,quantityIndex+1).split("").map(function(item) {return '#';} ).join("");

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbQtyText);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						////////////////////////
						// Non-win Symbol Key //
						////////////////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleLoseSymbolKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var symbIndex = 0; symbIndex < symbLosers.length; symbIndex++)
						{
							symbPrize   = symbLosers[symbIndex];
							canvasIdStr = 'cvsKeySymb' + symbPrize;
							elementStr  = 'eleKeySymb' + symbPrize;
							symbDesc    = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						////////////////////////////
						// Instant Win Symbol Key //
						////////////////////////////

						r.push('<div style="float:left">');
						r.push('<p>' + getTranslationByName("titleIWSymbolKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var symbIndex = 0; symbIndex < symbIWs.length; symbIndex++)
						{
							symbPrize    = symbIWs[symbIndex];
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'eleKeySymb' + symbPrize;
							boxColourStr = coloursIW[symbIndex];
							symbDesc     = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}
						
						r.push('<tr class="tablebody">');
						r.push('<td align="center">');
						r.push('<canvas id="cvsKeySymbBlank" width="' + (cellSize + 2 * cellMargin).toString() + '" height="' + (cellSize + 2 * cellMargin).toString() + '"></canvas>');
						r.push('</td>');
						r.push('</tr>');

						canvasIdStr = 'cvsKeySymb' + symbBonusGame;
						elementStr  = 'eleKeySymb' + symbBonusGame;
						symbDesc    = 'symb' + symbBonusGame;

						r.push('<tr class="tablebody">');
						r.push('<td align="center">');

						showSymb(canvasIdStr, elementStr, colourLime, colourBlack, symbBonusGame);

						r.push('</td>');
						r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
						r.push('</tr>');

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						function showMainGameSymbs(A_strCanvasId, A_strCanvasElement)
						{
							const mgCols = 5;
							const mgRows = 3;

							var canvasCtxStr   = 'canvasContext' + A_strCanvasElement;
							var cellIndex      = -1;
							var cellText       = '';
							var cellX          = 0;
							var cellY          = 0;
							var indexIWSymb    = -1;
							var indexWinSymb   = -1;
							var isBonusCell    = false;
							var isIWCell       = false;
							var isWinSymbCell  = false;
							var mgCanvasHeight = mgRows * cellSize + 2 * cellMargin;
							var mgCanvasWidth  = mgCols * cellSize + 2 * cellMargin;							
							var symbIndex      = -1;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + mgCanvasWidth.toString() + '" height="' + mgCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridRow = 0; gridRow < mgRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < mgCols; gridCol++)
								{
									cellIndex     = gridRow * mgCols + gridCol;
									symbCell      = scenarioMainGameData[cellIndex];
									indexWinSymb  = symbQuantities.indexOf(symbCell);
									indexIWSymb   = symbIWs.indexOf(symbCell);
									isWinSymbCell = (indexWinSymb != -1);
									isIWCell      = (indexIWSymb != -1);
									isBonusCell   = (symbCell == symbBonusGame);

									symbIndex     = (isWinSymbCell) ? indexWinSymb : ((isIWCell) ? indexIWSymb : -1);
									boxColourStr  = (isWinSymbCell) ? coloursWinSymb[symbIndex] : ((isIWCell) ? coloursIW[symbIndex] : ((isBonusCell) ? colourLime : colourWhite));
									cellX         = gridCol * cellSize;
									cellY         = gridRow * cellSize;
									cellText      = (isWinSymbCell) ? symbQuantities.slice(0,parseInt(symbCell,10)).split("").map(function(item) {return scenarioMainGameWinSymb;} ).join("") : symbCell;

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
									r.push(canvasCtxStr + '.fillText("' + cellText + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								}
							}

							r.push('</script>');
						}

						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablebody">');

						//////////
						// Grid //
						//////////

						canvasIdStr = 'cvsMainGrid';
						elementStr  = 'eleMainGrid';

						r.push('<td style="padding-right:50px; padding-bottom:25px">');

						showMainGameSymbs(canvasIdStr, elementStr);

						r.push('</td>');

						/////////////
						// Outcome //
						/////////////

						var iwSymbIndex = -1;
						var prizeStr    = '';
						var prizeText   = '';

						if (doMainGameWin)
						{
							canvasIdStr = 'cvsWinSymbPrize';
							elementStr  = 'eleWinSymbPrize';
							prizeText   = 'M' + mgScore.toString();
							prizeStr    = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];

							r.push('<td valign="top" style="padding-right:50px; padding-bottom:25px">');
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablebody">');
							r.push('<td>' + mgScore.toString() + ' x</td>');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, scenarioMainGameWinSymb);
							
							r.push('</td>');
							r.push('<td>= ' + prizeStr + '</td>');
							r.push('</tr>');
							r.push('</table>');
							r.push('</td>');
						}

						if (doInstantWins)
						{
							r.push('<td valign="top" style="padding-right:50px; padding-bottom:25px">');
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (var iwIndex = 0; iwIndex < mgInstantWins.length; iwIndex++)
							{
								symbPrize    = mgInstantWins[iwIndex];
								canvasIdStr  = 'cvsIWPrize' + symbPrize;
								elementStr   = 'eleIWPrize' + symbPrize;
								iwSymbIndex  = symbIWs.indexOf(symbPrize);
								boxColourStr = coloursIW[iwSymbIndex];
								prizeText    = 'I' + (iwSymbIndex+1).toString();
								prizeStr     = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];

								r.push('<tr class="tablebody">');
								r.push('<td align="center">');

								showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);
								
								r.push('</td>');
								r.push('<td>= ' + prizeStr + '</td>');
								r.push('</tr>');
							}

							r.push('</table>');
							r.push('</td>');
						}

						if (doBonusGame)
						{
							canvasIdStr = 'cvsBonusGameTrigger';
							elementStr  = 'eleBonusGameTrigger';

							r.push('<td valign="top" style="padding-right:50px; padding-bottom:25px">');
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, colourLime, colourBlack, symbBonusGame);
							
							r.push('</td>');
							r.push('<td>' + getTranslationByName("bonusGameTriggered", translations) + '</td>');
							r.push('</tr>');
							r.push('</table>');
							r.push('</td>');
						}

						r.push('</tr>');
						r.push('</table>');

						////////////////
						// Bonus Game //
						////////////////

						function showBonusGameTurn(A_strCanvasId, A_strCanvasElement, A_strData)
						{
							const bgCols = 16;

							var canvasCtxStr   = 'canvasContext' + A_strCanvasElement;
							var cellText       = '';
							var cellX          = 0;
							var indexWinSymb   = -1;
							var isWinSymbCell  = false;
							var bgCanvasHeight = cellSize + 2 * cellMargin;
							var bgCanvasWidth  = bgCols * cellSize + 2 * cellMargin;							

							r.push('<canvas id="' + A_strCanvasId + '" width="' + bgCanvasWidth.toString() + '" height="' + bgCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridCol = 0; gridCol < bgCols; gridCol++)
							{
								symbCell      = A_strData[gridCol];
								indexWinSymb  = symbQuantities.indexOf(symbCell);
								isWinSymbCell = (indexWinSymb != -1);

								boxColourStr  = (isWinSymbCell) ? coloursWinSymb[indexWinSymb] : colourWhite;
								cellX         = gridCol * cellSize;
								cellText      = (isWinSymbCell) ? symbQuantities.slice(0,parseInt(symbCell,10)).split("").map(function(item) {return symbBonusGame;} ).join("") : symbCell;

								r.push(canvasCtxStr + '.font = "bold 14px Arial";');
								r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
								r.push(canvasCtxStr + '.fillText("' + cellText + '", ' + (cellX + cellTextX).toString() + ', ' + cellTextY.toString() + ');');
							}

							r.push('</script>');
						}

						if (doBonusGame)
						{
							var keySymb   = -1;
							var symbRows  = Math.floor((symbBonusLosers.length + 1) / 2);
							var turnCount = 0;
							var turnStr   = '';

							r.push('<p>' + getTranslationByName("bonusGame", translations) + '</p>');

							////////////////////////
							// Non-win Symbol Key //
							////////////////////////

							r.push('<p>' + getTranslationByName("titleLoseSymbolKey", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablehead">');
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td style="padding-right:25px">' + getTranslationByName("keyDescription", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td style="padding-right:25px">' + getTranslationByName("keyDescription", translations) + '</td>');
							r.push('</tr>');

							for (var symbRowIndex = 0; symbRowIndex < symbRows; symbRowIndex++)
							{
								r.push('<tr class="tablebody">');

								for (var symbColIndex = 0; symbColIndex < 2; symbColIndex++)
								{
									keySymb      = symbColIndex * symbRows + symbRowIndex;
									symbPrize    = symbBonusLosers[keySymb];
									canvasIdStr  = 'cvsKeySymb' + symbPrize;
									elementStr   = 'eleKeySymb' + symbPrize;
									symbDesc     = 'symb' + symbPrize;

									r.push('<td align="center">');

									showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, symbPrize);

									r.push('</td>');
									r.push('<td style="padding-right:25px">' + getTranslationByName(symbDesc, translations) + '</td>');
								}

								r.push('</tr>');
							}

							r.push('</table>');

							//////////////////////
							// Bonus Game Turns //
							//////////////////////

							r.push('<br><table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (bonusTurnIndex = 0; bonusTurnIndex < scenarioBonusGameData.length; bonusTurnIndex++)
							{
								r.push('<tr class="tablebody">');

								//////////////////////////
								// Bonus Game Turn Info //
								//////////////////////////

								turnStr = getTranslationByName("turnNum", translations) + ' ' + (bonusTurnIndex+1).toString() + ' ' + getTranslationByName("turnOf", translations) + ' ' + scenarioBonusGameData.length.toString();

								r.push('<td valign="top">' + turnStr + '</td>');

								///////////////
								// Turn Grid //
								///////////////

								canvasIdStr = 'cvsBonusGrid' + bonusTurnIndex.toString();
								elementStr  = 'eleBonusGrid' + bonusTurnIndex.toString();

								r.push('<td style="padding-left:50px; padding-right:50px; padding-bottom:25px">');

								showBonusGameTurn(canvasIdStr, elementStr, scenarioBonusGameData[bonusTurnIndex]);

								r.push('</td>');

								////////////////////////
								// Bonus symbol count //
								////////////////////////

								turnCount = scenarioBonusGameData[bonusTurnIndex].replace(new RegExp('[^1-3]', 'g'), '').split("").map(function(item) {return parseInt(item,10);} ).reduce(function(a,b) {return a + b;}, 0);

								turnStr = getTranslationByName("bonusTurnCount", translations) + ' = ' + turnCount.toString();

								r.push('<td valign="top">' + turnStr + '</td>');
								r.push('</tr>');
							}

							r.push('</table>');

							//////////////////////
							// Bonus Game Prize //
							//////////////////////

							canvasIdStr = 'cvsBonusPrize';
							elementStr  = 'eleBonusPrize';
							prizeText   = 'B' + bgScore.toString();
							prizeStr    = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)];

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablebody">');
							r.push('<td>' + bgScore.toString() + ' x</td>');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, colourLime, colourBlack, symbBonusGame);
							
							r.push('</td>');
							r.push('<td>= ' + prizeStr + '</td>');
							r.push('</tr>');
							r.push('</table>');
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					function getMainGameWinSymb(scenario)
					{
						return scenario.split("|")[0];
					}

					function getMainGameData(scenario)
					{
						return scenario.split("|")[1];
					}

					function getBonusGameData(scenario)
					{
						return scenario.split("|")[2].split(",");
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
