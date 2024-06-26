extends CharacterBody3D

class_name Player

# Ganbiarra temporaria
@export var id: int;

const SPEED = 5.0;
const JUMP_VELOCITY = 4.5;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");
var knockback: Vector3 = Vector3.ZERO;

@onready var body = $Body;
@onready var animation = $AnimationPlayer as AnimationPlayer;
@onready var hitbox = $Body/Hitbox;
@onready var stun_timer: Timer = $stunTimer as Timer;

var life: float = 100.0;
var attackForce: float = 5.0;

var is_stunned: bool = false;

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("Attack"):
			apanhei(10, Vector3.RIGHT)

func _physics_process(delta):

	if not is_on_floor():
		velocity.y -= gravity * delta;
	is_on_ceiling()
	
	get_input(delta);
	
	if Input.is_action_just_pressed("Attack") and id == 1:
		# Coleta e filtra todos os nós do tipo Player que estão em contato com a hitbox
		var targetArray = hitbox.get_overlapping_bodies().filter(func(target): return target is Player) as Array[Player];
		
		for target in targetArray:
			if target != self:
				
				# Coleta a diferença entre a posição do alvo e o player e transforma num vetor de 0 ou 1.
				# Round arredonda todos os itens do vetor
				var _dir: Vector3 = ((target.global_position - global_position ).normalized()).round();
				
				# Chama o metodo de cada alvo passando o acumulado de dano e a direção para onde ele vai ser mandado
				target.apanhei(attackForce, _dir);
	
	move_and_slide();

func get_input(delta):
	
	# Se atordoado, nada do player pode ser atualizado
	if is_stunned:
		return;
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_stunned and id == 1:
		velocity.y = JUMP_VELOCITY;
	
	# Coleta o input do usuario e rotaciona o player 
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	
	# O player se move caso tenha uma direção
	if direction and id == 1:
		velocity.x = direction.x * SPEED;
		velocity.z = direction.z * SPEED;
		
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-direction.x, -direction.z), delta * 15);
		
		if animation.current_animation != "Run":
			animation.play("Run");
			
	# Caso não tenha, o velocity do player só vai voltar a 0 se ele estiver no chão, 
	# isso impede que a parabola do player seja cortada pela metade.
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED);
		velocity.z = move_toward(velocity.z, 0, SPEED);
		
		if animation.current_animation != "Idle":
			animation.play("Idle");

func apanhei(amount: float, dir: Vector3 ):
	
	# Dir.y geralmente vem 0, mas precimanos que seja 1 para simular um impulso para cima
	dir.y = 1;
	
	# atualiza a variavel global de velociade
	life -= amount;
	
	# calcula uma porcentagem sobre a vida
	var _force = 1.0 - life / 100.0;
	
	knockback = dir * attackForce * _force;
	
	# Aplica o knockback a velocity
	velocity = knockback;
	
	# Variavel usada na process para ligar ou desligar a movimentação padrão do player
	is_stunned = true;
	
	#timer que controla o tempo em que o player perde o controle
	stun_timer.start();

func _on_stun_timer_timeout():
	# Quando o tempo de atordoamento acaba a variavel fica falsa
	is_stunned = false;
