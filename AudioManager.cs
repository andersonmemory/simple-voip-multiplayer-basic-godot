using Godot;
using System;



public partial class AudioManager : Node
{
    private AudioStreamPlayer Input;

    private int index;

    private AudioEffectCapture effect;

    private AudioStreamGeneratorPlayback playback;

    public NodePath AudioOutputPath {get; set;}

    public override void _Ready() {

    }


    public override void _Processie(double delta) {

    }

    public void SetAudio(long id) {
        input = GetNode<AudioStreamPlayer>("Input");

        input.Stream = new AudioStreamMicrophone();

        input.Play();

        index = AudioServer.GetBusIndex("Record");

        effect = (AudioEffectCapture)AudioServer.GetBusEffect(index, 0);

        playback = GetNode<AudioStreamPlayer3D>("")

    }        
        
    }


}
