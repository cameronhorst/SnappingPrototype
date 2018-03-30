﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractableObject : MonoBehaviour
{
    public enum ColliderModeType
    {
        Self, Compound
    }

    public ColliderModeType colliderMode = ColliderModeType.Self;
    public bool interactable = true;
    public bool usePickupButton = true;
    public bool useInteractButton = false;
    public Rigidbody rb;

    public bool beingHeld = false;
    bool highlighted = false;

    VRSystemInput input;

    public virtual void Start()
    {
        input = VRSystemInput.Input;
        rb = GetComponent<Rigidbody>();
    }

    public virtual void OnCompoundTriggerEnter(Collider other)
    {
        if (other.gameObject.tag == "Controller")
        {
            other.GetComponent<HandInteractionController>().AddInteractableObject(this);
        }
    }

    public virtual void OnCompoundTriggerExit(Collider other)
    {
        if (other.gameObject.tag == "Controller")
        {
            other.GetComponent<HandInteractionController>().RemoveInteractableObject(this);
        }
    }

    public virtual void OnTriggerEnter(Collider other)
    {
        if (colliderMode == ColliderModeType.Compound) return;
        if(other.gameObject.tag == "Controller")
        {
            other.GetComponent<HandInteractionController>().AddInteractableObject(this);
        }
    }

    public virtual void OnTriggerExit(Collider other)
    {
        if (colliderMode == ColliderModeType.Compound) return;
        if (other.gameObject.tag == "Controller")
        {
            other.GetComponent<HandInteractionController>().RemoveInteractableObject(this);
        }
    }

    public virtual void OnBeginHighlight()
    {
        highlighted = true;
    }

    public virtual void OnEndHighlight()
    {
        highlighted = false;
    }

    public virtual void OnHoldInteractable(HandInteractionController handController)
    {
        beingHeld = true;
    }

    public virtual void OnReleaseInteractable(HandInteractionController handController)
    {
        beingHeld = false;

        //throw
        rb.velocity = handController.GetHandVelocity();
        rb.angularVelocity = handController.GetHandAngularVelocity();
    }

    public virtual void OnDropInteractable(HandInteractionController handController)
    {
        beingHeld = false;
    }
}