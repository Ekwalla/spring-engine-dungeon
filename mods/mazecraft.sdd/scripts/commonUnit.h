piece base, core, shell, gp;
static-var blocked;
#define SIG_Block 128

#define SMALL_MOVE [3]
#define SMALL_MOVE_SPEED [9]
#define LARGE_MOVE [5]
#define LARGE_MOVE_SPEED [10]

Create() {
	spin core around y-axis speed <20>;
	spin shell around y-axis speed <20>;
	sleep rand(0,1000);
	while(1) {
		move core to y-axis SMALL_MOVE speed SMALL_MOVE_SPEED;
		sleep 250;
		move shell to y-axis LARGE_MOVE speed LARGE_MOVE_SPEED;
		sleep 250;
		move core to y-axis 0- SMALL_MOVE speed SMALL_MOVE_SPEED;
		sleep 250;
		move shell to y-axis 0- LARGE_MOVE speed LARGE_MOVE_SPEED;
		sleep 250;
	}
}

QueryWeapon1(p) {
	p=gp;
}

AimFromWeapon1(p) {
	p=base;
}

AimWeapon1(h,p) {
	turn gp to y-axis h now;
	turn gp to x-axis 0 - p now;
	return 1;
}

Shot1() {
	move gp to x-axis [-8] + rand(0,16) * [1] now;
	move gp to y-axis [-8] + rand(0,16) * [1] now;
	move gp to z-axis [-8] + rand(0,16) * [1] now;
}

BlockShot1(target,block) {
	block=blocked;
}


BlockGun() {
	signal SIG_Block;
	set-signal-mask SIG_Block;
	blocked=1;
	sleep 2000;
	blocked=0;
}


QueryWeapon2(p) {
	p=base;
}

AimFromWeapon2(p) {
	p=base;
}

AimWeapon2(h,p) {
	return 1;
}

FireWeapon2() {
	call-script BlockGun();
}
