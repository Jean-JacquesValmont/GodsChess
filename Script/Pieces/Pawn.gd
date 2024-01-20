extends Sprite2D

signal promotionTurn

var dragging = false
var clickRadius = 50
var dragOffset = Vector2()
var moveCase = GlobalValueChessGame.oneMoveCase
var chessBoard = GlobalValueChessGame.chessBoard
var i = 8
var j = 2
var positionChessBoard
var Position = Vector2(50, 650)
@onready var nameOfPiece = get_name()
var initialPosition = true
var white = true
var textureWhite = preload("res://Image/Pieces/White/pawn_white.png")
var textureBlack = preload("res://Image/Pieces/Black/pawn_black.png")
var pieceProtectsAgainstAnAttack = false
var directionAttackProtectKing = ""
var promoteInProgress = false
var enPassant = false
var pieceProtectTheKing = false
var attackerPositionshiftI = 0
var attackerPositionshiftJ = 0
var attackerPositionshift2I = 0
var attackerPositionshift2J = 0
var playerID
var timer = -1

func _ready():
	await get_tree().process_frame
	positionChessBoard = get_parent().global_position
	if self.position.y == 650:
		white = true
	elif self.position.y == 150:
		white = false
	
	if OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
		playWhite()
	elif OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
		playBlack()

	if white == true and OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
		playerID = OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id
	elif white == false and OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
		playerID = OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id

#func _process(delta):
#	pass

func _input(event):
	if playerID == OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id:
		#J'ai un problème quand je met le bouton MOUSE_BUTTON_LEFT 2 fois dans deux if différent.
		#J'ai donc mit le MOUSE_BUTTON_RIGHT pour la promotion
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if promoteInProgress == true and GlobalValueChessGame.turnWhite == true and i == 2:
				promotionSelectionWhite()
			elif promoteInProgress == true and GlobalValueChessGame.turnWhite == false and i == 2:
				promotionSelectionBlack()
				
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT\
		and promoteInProgress == false and GlobalValueChessGame.checkmate == false and GlobalValueChessGame.stalemate == false:
			if (event.position - self.position - positionChessBoard).length() < clickRadius:
				# Start dragging if the click is on the sprite.
				if not dragging and event.pressed:
					dragging = true
					dragOffset = event.position - self.position - positionChessBoard
					z_index = 10
					theKingIsBehind()
					previewAllMove()
			# Stop dragging if the button is released.
			if dragging and not event.pressed:
				deleteAllChildMovePreview()
				get_node("Area2D/CollisionShape2D").disabled = false
				if white == true and GlobalValueChessGame.turnWhite == true:
					moveFinal(GlobalValueChessGame.checkWhite)
				elif white == false and GlobalValueChessGame.turnWhite == false:
					moveFinal(GlobalValueChessGame.checkBlack)
				self.position = Vector2(Position.x, Position.y)
				dragging = false
				z_index = 0
				print("chessBoard after moveFinal piece: ")
				for f in range(0,12):
					print(chessBoard[f])
					
		if event is InputEventMouseMotion and dragging:
			# While dragging, move the sprite with the mouse.
			self.position = event.position - positionChessBoard
			get_node("Area2D/CollisionShape2D").disabled = true
		
func move(dx, dy) :
	for f in range (1,2):
		var targetCaseX = dx*(f*moveCase)
		var targetCaseY = dy*(f*moveCase)
		var newTargetCaseX = targetCaseX + positionChessBoard.x
		var newTargetCaseY = targetCaseY + positionChessBoard.y
		if global_position.x >= (Position.x - 50) + newTargetCaseX  and global_position.x <= (Position.x + 50) + newTargetCaseX \
		and global_position.y >= (Position.y - 50) + newTargetCaseY and global_position.y <= (Position.y + 50) + newTargetCaseY \
		and ((chessBoard[i+(dy*f)][j+(dx*f)] == "0" or "Black" in chessBoard[i+(dy*f)][j+(dx*f)]) and GlobalValueChessGame.turnWhite == true\
		and (chessBoard[i+(dy*f)][j] == "0" or chessBoard[i+(dy*f)][j] != "0")\
		or (chessBoard[i+(dy*f)][j+(dx*f)] == "0" or "White" in chessBoard[i+(dy*f)][j+(dx*f)]) and GlobalValueChessGame.turnWhite == false\
		and (chessBoard[i+(dy*f)][j] == "0" or chessBoard[i+(dy*f)][j] != "0")):
			rpc("movePiece",f,targetCaseX,targetCaseY,dx,dy)
			break
		elif global_position.x >= get_parent().texture.get_width() + positionChessBoard.x\
		 or global_position.y >= get_parent().texture.get_height() + positionChessBoard.y :
			self.position = Vector2(Position.x, Position.y)

@rpc("any_peer", "call_local") func movePiece(f,targetCaseX,targetCaseY,dx,dy):
	if GlobalValueChessGame.turnWhite == true:
		if OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
			self.position = Vector2((Position.x + targetCaseX), (Position.y + targetCaseY))
			chessBoard[i][j] = "0"
			i=i+(dy*f)
			j=j+(dx*f)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
		elif OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
			self.position = Vector2((Position.x - targetCaseX), (Position.y - targetCaseY))
			chessBoard[i][j] = "0"
			i=i-(dy*f)
			j=j-(dx*f)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
			GlobalValueChessGame.chessBoard = GlobalValueChessGame.reverseChessBoard(chessBoard)
	elif GlobalValueChessGame.turnWhite == false:
		if OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
			self.position = Vector2((Position.x - targetCaseX), (Position.y - targetCaseY))
			chessBoard[i][j] = "0"
			i=i-(dy*f)
			j=j-(dx*f)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
		elif OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
			self.position = Vector2((Position.x + targetCaseX), (Position.y + targetCaseY))
			chessBoard[i][j] = "0"
			i=i+(dy*f)
			j=j+(dx*f)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
			GlobalValueChessGame.chessBoard = GlobalValueChessGame.reverseChessBoard(chessBoard)
	Position = Vector2(self.position.x, self.position.y)
	initialPosition = false
	if chessBoard[i][j].begins_with("PawnWhite") and (i == 2 or i == 9): #Sinon le promoteInProgress ne passe pas à true pour le player 2
		promotion("White","Cavalier", "Fou", "Tour", "Reine")
	elif chessBoard[i][j].begins_with("PawnBlack") and (i == 2 or i == 9): #Sinon le promoteInProgress ne passe pas à true pour le player 1
		promotion("Black","Cavalier", "Fou", "Tour", "Reine")
	if promoteInProgress == false:
		GlobalValueChessGame.turnWhite = !GlobalValueChessGame.turnWhite
	get_node("SoundMovePiece").play()
	resetLastMovePlay()
	lastMovePlay()

@rpc("any_peer", "call_local") func enPassantRPC(boolen):
	enPassant = boolen

func moveWithPinWhite(dx,dy,enPassantI):
	if pieceProtectsAgainstAnAttack == false:
		if initialPosition == true:
			if chessBoard[i+dy][j] == "0":
				move(0,dy)
			if chessBoard[i+dy*2][j] == "0":
				move(0,dy*2)
			if chessBoard[i+dy][j-dx] != "0":
				move(-dx,dy)
			if chessBoard[i+dy][j+dx] != "0":
				move(dx,dy)
			rpc("enPassantRPC", true)
		else :
			if i == enPassantI and chessBoard[i][j-dx].begins_with("Pawn")\
			and get_node("/root/Game/ChessBoard/" + chessBoard[i][j-dx]).enPassant == true:
				get_node("/root/Game/ChessBoard/" + chessBoard[i][j-dx]).queue_free()
				chessBoard[i][j-dx] = "0"
				move(-dx,dy)
			if i == enPassantI and chessBoard[i][j+dx].begins_with("Pawn")\
			and get_node("/root/Game/ChessBoard/" + chessBoard[i][j+dx]).enPassant == true:
				get_node("/root/Game/ChessBoard/" + chessBoard[i][j+dx]).queue_free()
				chessBoard[i][j+dx] = "0"
				move(dx,dy)
			if chessBoard[i+dy][j] == "0":
				move(0,dy)
			if chessBoard[i+dy][j-dx] != "0":
				move(-dx,dy)
			if chessBoard[i+dy][j+dx] != "0":
				move(dx,dy)
			rpc("enPassantRPC", false)
	elif pieceProtectsAgainstAnAttack == true:
		if initialPosition == true:
			if directionAttackProtectKing == "Haut":
				if chessBoard[i+dy][j] == "0":
					move(0,dy)
				if chessBoard[i+dy*2][j] == "0":
					move(0,dy*2)
			elif directionAttackProtectKing == "Haut/Gauche":
				if chessBoard[i+dy][j-dx] != "0":
					move(-dx,dy)
			elif directionAttackProtectKing == "Haut/Droite":
				if chessBoard[i+dy][j+dx] != "0":
					move(dx,dy)
			rpc("enPassantRPC", true)
		else :
			if directionAttackProtectKing == "Haut":
				if chessBoard[i+dy][j] == "0":
					move(0,dy)
			elif directionAttackProtectKing == "Haut/Gauche":
				if chessBoard[i+dy][j-dx] != "0":
					move(-dx,dy)
			elif directionAttackProtectKing == "Haut/Droite":
				if chessBoard[i+dy][j+dx] != "0":
					move(dx,dy)
			rpc("enPassantRPC", false)

func defenceMove(attacki,attackj):
	print("Enter in defenceMove")
	var targetCaseX = (attackj - j) * moveCase
	var targetCaseY = (attacki - i) * moveCase
	var newTargetCaseX = targetCaseX + positionChessBoard.x
	var newTargetCaseY = targetCaseY + positionChessBoard.y
	if global_position.x >= (Position.x - 50) + newTargetCaseX  and global_position.x <= (Position.x + 50) + newTargetCaseX \
	and global_position.y >= (Position.y - 50) + newTargetCaseY and global_position.y <= (Position.y + 50) + newTargetCaseY \
	and ((chessBoard[attacki][attackj] == "0" or "Black" in chessBoard[attacki][attackj]) and GlobalValueChessGame.turnWhite == true\
	or (chessBoard[attacki][attackj] == "0" or "White" in chessBoard[attacki][attackj]) and GlobalValueChessGame.turnWhite == false):
		rpc("moveDefencePiece",targetCaseX,targetCaseY,attacki,attackj)
	elif global_position.x >= get_parent().texture.get_width() + positionChessBoard.x\
		 or global_position.y >= get_parent().texture.get_height() + positionChessBoard.y :
		self.position = Vector2(Position.x, Position.y)

@rpc("any_peer", "call_local") func moveDefencePiece(targetCaseX,targetCaseY,attacki,attackj):
	if GlobalValueChessGame.turnWhite == true:
		if OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
			self.position = Vector2((Position.x + targetCaseX), (Position.y + targetCaseY))
			chessBoard[i][j] = "0"
			i=attacki
			j=attackj
			chessBoard[i][j] = nameOfPiece.replace("@", "")
		elif OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
			self.position = Vector2((Position.x - targetCaseX), (Position.y - targetCaseY))
			chessBoard[i][j] = "0"
			i=reverseCoordonate(attacki)
			j=reverseCoordonate(attackj)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
			GlobalValueChessGame.chessBoard = GlobalValueChessGame.reverseChessBoard(chessBoard)
	elif GlobalValueChessGame.turnWhite == false:
		if OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id == 1:
			self.position = Vector2((Position.x - targetCaseX), (Position.y - targetCaseY))
			chessBoard[i][j] = "0"
			i=reverseCoordonate(attacki)
			j=reverseCoordonate(attackj)
			chessBoard[i][j] = nameOfPiece.replace("@", "")
		elif OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id != 1:
			self.position = Vector2((Position.x + targetCaseX), (Position.y + targetCaseY))
			chessBoard[i][j] = "0"
			i=attacki
			j=attackj
			chessBoard[i][j] = nameOfPiece.replace("@", "")
			GlobalValueChessGame.chessBoard = GlobalValueChessGame.reverseChessBoard(chessBoard)
	Position = Vector2(self.position.x, self.position.y)
	if chessBoard[i][j].begins_with("PawnWhite") and i == 2:
		promotion("White","Cavalier", "Fou", "Tour", "Reine")
	elif chessBoard[i][j].begins_with("PawnBlack") and i == 2:
		promotion("Black","Cavalier", "Fou", "Tour", "Reine")
	if promoteInProgress == false:
		GlobalValueChessGame.turnWhite = !GlobalValueChessGame.turnWhite
	initialPosition = false
	attackerPositionshiftI = 0
	attackerPositionshiftJ = 0
	attackerPositionshift2I = 0
	attackerPositionshift2J = 0
	pieceProtectTheKing = false
	get_node("SoundMovePiece").play()
	resetLastMovePlay()
	lastMovePlay()

func moveFinal(checkColor):
	if checkColor == false:
		moveWithPinWhite(1,-1,5) #Le premier paramètre restera toujours 1, le 2nd doit varier entre 1 et -1 (bas/haut).
	elif checkColor == true and pieceProtectTheKing == true:
		if pieceProtectsAgainstAnAttack == false:
			defenceMove(attackerPositionshiftI,attackerPositionshiftJ)
			defenceMove(attackerPositionshift2I,attackerPositionshift2J)

func _on_area_2d_area_entered(area):
		var pieceName = area.get_parent().get_name()
		if promoteInProgress == false:
			if white == true and GlobalValueChessGame.turnWhite == false:
				if GlobalValueMenu.godSelectPlayer2 == "GodOfDeath":
#					deadPower()
					pass
				if "Black" in pieceName and dragging == false :
					get_node("/root/Game/ChessBoard/" + pieceName).queue_free()
			elif white == false and GlobalValueChessGame.turnWhite == true:
				enablePowerOfDeath(pieceName)
				if "White" in pieceName and dragging == false :
					get_node("/root/Game/ChessBoard/" + pieceName).queue_free()
		elif promoteInProgress == true:
			if white == true and GlobalValueChessGame.turnWhite == true:
				if GlobalValueMenu.godSelectPlayer2 == "GodOfDeath":
#					deadPower()
					pass
				if "Black" in pieceName and dragging == false :
					get_node("/root/Game/ChessBoard/" + pieceName).queue_free()
			elif white == false and GlobalValueChessGame.turnWhite == false:
				enablePowerOfDeath(pieceName)
				if "White" in pieceName and dragging == false :
					get_node("/root/Game/ChessBoard/" + pieceName).queue_free()

func findDirectionAttackRow(dx, dy, rookColor, queenColor):
	for f in range(1,9):
		if chessBoard[i+(dy*f)][j+(dx*f)] == "x":
			break
		elif chessBoard[i+(dy*f)][j+(dx*f)] != "0":
			if chessBoard[i+(dy*f)][j+(dx*f)].begins_with(rookColor)\
			or chessBoard[i+(dy*f)][j+(dx*f)].begins_with(queenColor):
				if dx == 0 and dy == -1:
					directionAttackProtectKing = "Haut"
				elif dx == 0 and dy == 1:
					directionAttackProtectKing = "Bas"
				elif dx == 1 and dy == 0:
					directionAttackProtectKing = "Droite"
				elif dx == -1 and dy == 0:
					directionAttackProtectKing = "Gauche"
				break
			else:
				break

func findDirectionAttackDiagonal(dx, dy, bishopColor, queenColor):
	for f in range(1,9):
		if chessBoard[i+(dy*f)][j+(dx*f)] == "x":
			break
		elif chessBoard[i+(dy*f)][j+(dx*f)] != "0":
			if chessBoard[i+(dy*f)][j+(dx*f)].begins_with(bishopColor)\
			or chessBoard[i+(dy*f)][j+(dx*f)].begins_with(queenColor):
				if dx == 1 and dy == -1:
					directionAttackProtectKing = "Haut/Droite"
				elif dx == -1 and dy == -1:
					directionAttackProtectKing = "Haut/Gauche"
				elif dx == 1 and dy == 1:
					directionAttackProtectKing = "Bas/Droite"
				elif dx == -1 and dy == 1:
					directionAttackProtectKing = "Bas/Gauche"
				break
			else:
				break

func directionOfAttack(bishopColor, rookColor, queenColor):
	#On regarde d'où vient l'attaque
	directionAttackProtectKing = ""
	#Lignes
	findDirectionAttackRow(0, -1, rookColor, queenColor)
	findDirectionAttackRow(0, 1, rookColor, queenColor)
	findDirectionAttackRow(1, 0, rookColor, queenColor)
	findDirectionAttackRow(1, 0, rookColor, queenColor)
	
	#Diagonales
	findDirectionAttackDiagonal(1, -1, bishopColor, queenColor)
	findDirectionAttackDiagonal(-1, -1, bishopColor, queenColor)
	findDirectionAttackDiagonal(1, 1, bishopColor, queenColor)
	findDirectionAttackDiagonal(-1, 1, bishopColor, queenColor)
	
func findtheKingIsBehind(dx, dy, kingColor):
	for f in range(1,9):
		if chessBoard[i+(dy*f)][j+(dx*f)] == "x":
			break
		elif chessBoard[i+(dy*f)][j+(dx*f)] != "0":
			if chessBoard[i+(dy*f)][j+(dx*f)].begins_with(kingColor):
				pieceProtectsAgainstAnAttack = true
				break
			else:
				break

func theKingIsBehind():
	#Ensuite, on regarde si le roi est derrière la pièce
	#qui le protège de l'attaque qui vient dans cette direction
	var kingColor = ""
	if GlobalValueChessGame.turnWhite == true :
		directionOfAttack("BishopBlack", "RookBlack", "QueenBlack")
		kingColor = "KingWhite"
	elif GlobalValueChessGame.turnWhite == false :
		directionOfAttack("BishopWhite", "RookWhite", "QueenWhite")
		kingColor = "KingBlack"
		
	pieceProtectsAgainstAnAttack = false
	if directionAttackProtectKing == "Haut":
		#On cherche vers le bas
		findtheKingIsBehind(0, 1, kingColor)
	elif directionAttackProtectKing == "Bas":
		#On cherche vers le haut
		findtheKingIsBehind(0, -1, kingColor)
	elif directionAttackProtectKing == "Droite":
		#On cherche vers la gauche
		findtheKingIsBehind(-1, 0, kingColor)
	elif directionAttackProtectKing == "Gauche":
		#On cherche vers la droite
		findtheKingIsBehind(1, 0, kingColor)
	elif directionAttackProtectKing == "Haut/Droite":
		#On cherche vers le Bas/Gauche
		findtheKingIsBehind(-1, 1, kingColor)
	elif directionAttackProtectKing == "Haut/Gauche":
		#On cherche vers le Bas/Droite
		findtheKingIsBehind(1, 1, kingColor)
	elif directionAttackProtectKing == "Bas/Droite":
		#On cherche vers le Haut/Gauche
		findtheKingIsBehind(-1, -1, kingColor)
	elif directionAttackProtectKing == "Bas/Gauche":
		#On cherche vers le Haut/Droite
		findtheKingIsBehind(1, -1, kingColor)

func promotion(color,knight,bishop,rook,queen):
	print("Enter in promotion")
	# Les noms des pièces de promotion et leurs positions x correspondantes
	var promotionPieces = [knight,bishop,rook,queen]
	var xPositions = [0, 200, 400, 600]
	
	if playerID == OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id:
		for i in range(len(promotionPieces)):
			var promotion_sprite = Sprite2D.new()
			if color == "White":
				promotion_sprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - " + promotionPieces[i] + ".png")
			elif color == "Black":
				promotion_sprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - " + promotionPieces[i] + ".png")
			promotion_sprite.centered = false
			promotion_sprite.position.x = xPositions[i]
			promotion_sprite.position.y = 300
			get_parent().add_child(promotion_sprite)
		
	promoteInProgress = true
	emit_signal("promotionTurn", promoteInProgress)
		
func namingPromotion(piece):
	var numberMax = 0
	var pieceFind = false
	for f in range(2,10): 
		for ff in range(2,10):
			if chessBoard[f][ff].begins_with(piece):
				pieceFind = true
				for fff in range(2,11):
					if chessBoard[f][ff] == piece + str(fff):
						if fff > numberMax:
							numberMax = fff
	if piece + str(numberMax) == piece + "0" and pieceFind == false:
		chessBoard[i][j] = piece
		set_name(piece)
	elif piece + str(numberMax) == piece + "0" and pieceFind == true:
		chessBoard[i][j] = piece + "2"
		set_name(piece)
	elif numberMax != 0:
		chessBoard[i][j] = piece + str(numberMax+1)
		set_name(piece + str(numberMax+1))

func deletePiecesSelectionPromotion():
	if playerID == OnlineMatch._nakama_multiplayer_bridge.multiplayer_peer._self_id:
		var numberOfChildren = get_parent().get_child_count()
		for f in range(numberOfChildren - 4, numberOfChildren):
			var child = get_parent().get_child(f)
			child.queue_free()

func promotionSelectionWhite():
	print("Enter in promotionSelection: ", self.nameOfPiece)
	#Du faite que j'ai diviser par 2 la taille du pion, les distances de mousePos sont doubler quand je clique.
	#Donc je divise par 2 mousePos pour avoir les bonnes valeurs.
	var mousePos = get_local_mouse_position()/2
	var promotionOptions = [
	[0, 200, "KnightWhite", "Knight.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Cavalier.png"],
	[200, 400, "BishopWhite", "Bishop.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Fou.png"],
	[400, 600, "RookWhite", "Rook.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Tour.png"],
	[600, 800, "QueenWhite", "Queen.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Reine.png"]
	]
	
	for f in range(4):
		print("Enter in promotionSelection boucle for")
		var minX = promotionOptions[f][0]
		var maxX = promotionOptions[f][1]
		var promotionName = promotionOptions[f][2]
		var scriptPath = promotionOptions[f][3]
		var texturePath = promotionOptions[f][4]
		
		if mousePos.x >= minX - position.x and mousePos.x <= maxX - position.x \
		and mousePos.y >= 250 and mousePos.y <= 450:
			rpc("promotionSelectionSelect",texturePath,promotionName,scriptPath)
			break  # Sortir de la boucle après avoir trouvé une correspondance

func promotionSelectionBlack():
	print("Enter in promotionSelection: ", self.nameOfPiece)
	#Du faite que j'ai diviser par 2 la taille du pion, les distances de mousePos sont doubler quand je clique.
	#Donc je divise par 2 mousePos pour avoir les bonnes valeurs.
	var mousePos = get_local_mouse_position()/2
	var promotionOptions = [
	[0, 200, "KnightBlack", "Knight.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Cavalier.png"],
	[200, 400, "BishopBlack", "Bishop.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Fou.png"],
	[400, 600, "RookBlack", "Rook.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Tour.png"],
	[600, 800, "QueenBlack", "Queen.gd", "res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Reine.png"]]

	for f in range(4):
		print("Enter in promotionSelection boucle for")
		var minX = promotionOptions[f][0]
		var maxX = promotionOptions[f][1]
		var promotionName = promotionOptions[f][2]
		var scriptPath = promotionOptions[f][3]
		var texturePath = promotionOptions[f][4]
		
		if mousePos.x >= minX - position.x and mousePos.x <= maxX - position.x \
		and mousePos.y >= 250 and mousePos.y <= 450:
			rpc("promotionSelectionSelect",texturePath,promotionName,scriptPath)
			break  # Sortir de la boucle après avoir trouvé une correspondance

@rpc("any_peer","call_local") func promotionSelectionSelect(texturePath,promotionName,scriptPath):
	print("Enter in promotionSelection selection piece")
	texture = load(texturePath)
	namingPromotion(promotionName)
	deletePiecesSelectionPromotion()
	promoteInProgress = false
	emit_signal("promotionTurn", promoteInProgress)
	get_parent().promotionID = get_instance_id()
	set_script(load("res://Script/Pieces/" + scriptPath))
	GlobalValueChessGame.turnWhite = !GlobalValueChessGame.turnWhite

func get_promoteInProgress():
	return promoteInProgress

func createNewPieceMovePreview(dx,dy,f,color):
	var previewSprite = Sprite2D.new()
	if color == "White":
		previewSprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Pion.png")
	elif color == "Black":
		previewSprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Pion.png")
	previewSprite.centered = true
	previewSprite.position.x = Position.x + positionChessBoard.x + (100 * f*dx)
	previewSprite.position.y = Position.y + positionChessBoard.y + (100 * f*dy)
	previewSprite.z_index = 9
	previewSprite.modulate.a = 0.5
	previewSprite.scale.x = 0.5
	previewSprite.scale.y = 0.5
	get_node("/root/Game/MovePreview").add_child(previewSprite)

func createNewPieceDefenceMovePreview(attackI, attackJ, color):
	var previewSprite = Sprite2D.new()
	if color == "White":
		previewSprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer1 + "/Pieces/Base pièce doubler - Pion.png")
	elif color == "Black":
		previewSprite.texture = load("res://Image/Gods/" + GlobalValueMenu.godSelectPlayer2 + "/Pieces/Base pièce doubler - Pion.png")
	previewSprite.centered = true
	previewSprite.position.x = Position.x + positionChessBoard.x + (100 * (attackJ - j))
	previewSprite.position.y = Position.y + positionChessBoard.y + (100 * (attackI - i))
	previewSprite.z_index = 9
	previewSprite.modulate.a = 0.1
	previewSprite.scale.x = 0.5
	previewSprite.scale.y = 0.5
	get_node("/root/Game/MovePreview").add_child(previewSprite)

func previewMove(dx, dy, color, color2, attackI, attackJ, attack2I, attack2J):
	if (GlobalValueChessGame.checkWhite == false and white == true)\
	or (GlobalValueChessGame.checkBlack == false and white == false):
		for f in range (1,2):
			if chessBoard[i+(f*dy)][j+(f*dx)] == "x":
				break
			if chessBoard[i+(f*dy)][j+(f*dx)] == "0" and dx == 0 :
				createNewPieceMovePreview(dx,dy,f,color)
			elif chessBoard[i+(f*dy)][j+(f*dx)] != "0" and color2 in chessBoard[i+(f*dy)][j+(f*dx)]:
				createNewPieceMovePreview(dx,dy,f,color)
			elif chessBoard[i+(f*dy)][j+(f*dx)] != "0" and color in chessBoard[i+(f*dy)][j+(f*dx)]:
				break
	elif (GlobalValueChessGame.checkWhite == true and white == true)\
	or (GlobalValueChessGame.checkBlack == true and white == false):
		if chessBoard[attackI][attackJ] == "0"\
		or chessBoard[attackI][attackJ] != "0":
			createNewPieceDefenceMovePreview(attackI, attackJ, color)
		if chessBoard[attack2I][attack2J] == "0"\
		or chessBoard[attack2I][attack2J] != "0":
			createNewPieceDefenceMovePreview(attack2I, attack2J, color)

func previewMovePattern(dy,color, color2):
	if initialPosition == true :
		previewMove(0, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
		previewMove(0, 2*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
		previewMove(-1, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
		previewMove(1, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
	elif initialPosition == false :
		previewMove(0, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
		previewMove(-1, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)
		previewMove(1, 1*dy, color, color2,attackerPositionshiftI,attackerPositionshiftJ,attackerPositionshift2I,attackerPositionshift2J)

func previewAllMove():
		if white == true:
			previewMovePattern(-1,"White", "Black")
		elif white == false:
			previewMovePattern(-1,"Black", "White")

func deleteAllChildMovePreview():
	var numberOfChildren = get_node("/root/Game/MovePreview").get_child_count()
	for f in range(numberOfChildren):
		get_node("/root/Game/MovePreview").get_child(f).queue_free()

func lastMovePlay():
	modulate.r = 0
	modulate.g = 0

func resetLastMovePlay():
	var numberOfChildren = get_parent().get_child_count()
	
	for f in range(numberOfChildren):
		if get_parent().get_child(f).modulate.r == 0\
		and get_parent().get_child(f).modulate.g == 0:
			get_parent().get_child(f).modulate = Color(1, 1, 1, 1)
			break

func playWhite():
	chessBoard = GlobalValueChessGame.chessBoard
		
	if white == true:
		set_name("PawnWhite")
		nameOfPiece = get_name()
		if nameOfPiece == "PawnWhite":
			i = 8
			j = 2
			self.position = Vector2(50,650)
			Position = Vector2(50,650)
		for f in range(2, 9):
			if nameOfPiece == "PawnWhite" + str(f) :
				j = f + 1
				self.position.x = ((50 + f * 100) - 100)
				self.position.y = 650
				Position.x = ((50 + f * 100) - 100)
				Position.y = 650
	else:
		i = 3
		j = 2
		self.position = Vector2(50,150)
		Position = Vector2(50,150)
		texture = textureBlack
		set_name("PawnBlack")
		nameOfPiece = get_name()
		for f in range(2, 9):
			if nameOfPiece == "PawnBlack" + str(f) :
				j = f + 1
				self.position.x = ((50 + f * 100) - 100)
				self.position.y = 150
				Position.x = (50 + f * 100) - 100
				Position.y = 150
		
	print(nameOfPiece, " i: ", i, " j: ", j, " new position: ", Position )

func playBlack():
	chessBoard = GlobalValueChessGame.chessBoardReverse
		
	if white == true:
		set_name("PawnWhite")
		nameOfPiece = get_name()
		if nameOfPiece == "PawnWhite":
			i = 3
			j = 9
			self.position = Vector2(750,150)
			Position = Vector2(750,150)
		for f in range(2, 9):
			if nameOfPiece == "PawnWhite" + str(f) :
				i = 3
				j = 10 - f
				self.position.x = 850 - f * 100
				self.position.y = 150
				Position.x = 850 - f * 100
				Position.y = 150
	else:
		i = 8
		j = 9
		self.position = Vector2(750,650)
		Position = Vector2(750,650)
		texture = textureBlack
		set_name("PawnBlack")
		nameOfPiece = get_name()
		for f in range(2, 9):
			if nameOfPiece == "PawnBlack" + str(f) :
				i = 8
				j = 10 - f
				self.position.x = 850 - f * 100
				self.position.y = 650
				Position.x = 850 - f * 100
				Position.y = 650
		
	print(nameOfPiece, " i: ", i, " j: ", j, " new position: ", Position )

func reverseCoordonate(i):
	match i:
		2:
			i = 9
		3:
			i = 8
		4:
			i = 7
		5:
			i = 6
		6:
			i = 5
		7:
			i = 4
		8:
			i = 3
		9:
			i = 2
	return i

################################################################################
#Power of Gods

func enablePowerOfDeath(pieceName):
	if GlobalValueMenu.godSelectPlayer1 == "GodOfDeath":
		if "PawnWhite" in pieceName:
			PowersOfGods.deathPowerPawn(playerID, chessBoard)
		elif "KnightWhite" in pieceName:
			PowersOfGods.deathPower(playerID,7)
		elif "BishopWhite" in pieceName:
			PowersOfGods.deathPower(playerID,9)
		elif "RookWhite" in pieceName:
			PowersOfGods.deathPower(playerID,11)
		elif "QueenWhite" in pieceName:
			PowersOfGods.deathPower(playerID,13)

func deadPowerTimer():
	if get_node("Timer").visible == true and GlobalValueChessGame.turnWhite == true :
		timer -= 1
		get_node("Timer").text = str(timer)
	if timer == 0:
		chessBoard[i][j] = "0"
		self.queue_free()
